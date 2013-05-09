fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec
EventEmitter = require('events').EventEmitter
_when = require 'when'

VERSION = '0.1.3'

RAR_ID = new Buffer 'Rar!\x1a\x07\x00'
RAR_TOOL = 'unrar'
LIST_PARAMS = ['lb']
EXTRACT_PARAMS = ['p', '-y', '-idq']
VIEW_TOOL = 'kview'
MAX_BUFFER_SIZE = 1024 * 1024 * 10 
DEFAULT_ENCODING = 'binary'

isRarFile =  (filename, cb) =>
   try
     data = fs.readFileSync(filename)
     #ret = RAR_ID is data[0...RAR_ID.length]
     ret = true
     for n in [0...RAR_ID.length]
       if data[n] isnt RAR_ID[n] 
         ret = false
         break

     if cb
       cb null, ret
     return ret

   catch e
     if cb 
       cb e, null
     else
       throw e


class RarFile extends EventEmitter
  @VERSION = VERSION

  constructor: (@archiveName, options) ->
    if not @archiveName
      throw new Error 'Must provide a filename.'
    if not isRarFile @archiveName
      throw new Error "#{@archiveName} is not a RAR archive"
    @rarTool = options?.rarTool or RAR_TOOL 
    @debugMode = options?.debugMode or false
    @viewTool = options?.viewTool or VIEW_TOOL
    @_loadedList = false
    @names =  []
    @on 'ready', (who) =>
      console.log who.toString() if who.debugMode
      
    @_loadNames()
    .then(
      ((readStream) =>
        @names = (f for f in readStream.split '\n' when (f and f isnt 'undefined'))
        @_loadedList = true
        #@emit 'ready', @
        @
      ),
      ((err) =>
        console.log "Throwing error #{err.toString()} produced while loading names from the RAR archive"
        throw err
      )
    )
    .then(
      (dis) =>
        dis.emit 'ready', dis
    )

  _loadNames: () =>
     params = "#{LIST_PARAMS.join ' '} #{@archiveName}"
     executable = "#{@rarTool} #{params}"
     console.log "Running << #{executable} >>" if @debugMode
     deferred = _when.defer()
     exec executable, encoding: "utf8", maxBuffer: MAX_BUFFER_SIZE, (err, stdout, stderr) =>
       if err
         deferred.reject err
       else
         deferred.resolve stdout
     deferred.promise
     
     
  readStream: (filename) =>
    params =  (p for p in EXTRACT_PARAMS)
    params.push @archiveName
    params.push filename
    console.log "Running << #{@rarTool} #{JSON.stringify(params)} >>" if @debugMode
    unrar = spawn @rarTool, params
    unrar.stdout.setEncoding 'binary'
    return unrar.stdout

  ###  
  readFile: (filename, cb) =>
    params = "#{EXTRACT_PARAMS.join ' '} #{@archiveName} #{filename}"
    executable = "#{@rarTool} #{params}"
    console.log "Running << #{executable} >>" if @debugMode
    exec executable, encoding: 'binary', maxBuffer: MAX_BUFFER_SIZE, (err, stdout, stderr) =>
      cb err, stdout
  ###

  readFile: (filename, cb) =>
    ( =>
        deferred = _when.defer()
        fdata = ''
        rStream = @readStream filename
        rStream.on 'error', (err) -> deferred.reject err
        rStream.on 'data', (chunk) -> fdata += chunk
        rStream.on 'end', () -> deferred.resolve fdata
        deferred.promise
    )().
    then(
      ((data) =>
         cb null, data
      
      ),
      ((err) =>
         cb err, null
      )
    )
    
  showFile: (filename) =>
    @readFile filename, (err, data) =>
      if err
        console.log err.toString()
        return
      fs.writeFileSync filename, data, 'binary'
      
      console.log "Length of extracted data: #{data.length}"
      try
       show  = spawn  @viewTool, [filename]
      catch e
        console.log e.toString()

  toString: () =>
      JSON.stringify names: @names
 

module.exports = {VERSION, isRarFile, RarFile}


