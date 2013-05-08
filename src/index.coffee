fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec
EventEmitter = require('events').EventEmitter

VERSION = '0.1.0'

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

  constructor: (@archiveName) ->
    if not @archiveName
      throw new Error 'Must provide a filename.'
    if not isRarFile @archiveName
      throw new Error "#{@archiveName} is not a RAR archive"
    @debugMode = false
    @viewTool = VIEW_TOOL
    @_loadedList = false
    @names =  []
    @_loadNames()

  _loadNames: () =>
     params = "#{LIST_PARAMS.join ' '} #{@archiveName}"
     executable = "#{RAR_TOOL} #{params}"
     console.log "Running << #{executable} >>" if @debugMode
     exec executable, encoding: "utf8", maxBuffer: MAX_BUFFER_SIZE, (err, stdout, stderr) =>
       @names = (f for f in stdout.split '\n' when (f and f isnt 'undefined'))
       @_loadedList = true
       @emit 'ready', @
     @
     
     
  readStream: (filename) =>
    params =  (p for p in EXTRACT_PARAMS)
    params.push @archiveName
    params.push filename
    console.log "Running << #{RAR_TOOL} #{JSON.stringify(params)} >>" if @debugMode
    unrar = spawn RAR_TOOL, params
    unrar.stdout.setEncoding 'binary'
    return unrar.stdout
  
  readFile: (filename, cb) =>
    params = "#{EXTRACT_PARAMS.join ' '} #{@archiveName} #{filename}"
    executable = "#{RAR_TOOL} #{params}"
    console.log "Running << #{executable} >>" if @debugMode
    exec executable, encoding: 'binary', maxBuffer: MAX_BUFFER_SIZE, (err, stdout, stderr) =>
      cb err, stdout

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


