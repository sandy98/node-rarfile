fs = require 'fs'
spawn = require('child_process').spawn
exec = require('child_process').exec
EventEmitter = require('events').EventEmitter
_when = require 'when'

VERSION = '0.2.3-1'

RAR_ID = new Buffer 'Rar!\x1a\x07\x00'
RAR_TOOL = 'unrar'
LIST_PARAMS = ['vb']
EXTRACT_PARAMS = ['p', '-y', '-idq']
VIEW_TOOL = 'kview'
MAX_BUFFER_SIZE = 1024 * 1024 * 10 
DEFAULT_ENCODING = 'binary'


isRarFile =  (filename, cb) =>
   try
     fd = fs.openSync filename, 'r'
     data = new Buffer(RAR_ID.length)
     fs.readSync(fd, data, 0, RAR_ID.length)
     fs.closeSync fd
     ret = data.inspect() is RAR_ID.inspect()
     if cb
       cb null, ret
     return ret
   catch e
     if cb 
       cb e, null
     else
       console?.log? e.toString()


class RarFile extends EventEmitter

  @VERSION = VERSION

  constructor: (@archiveName, options) ->
    @rarTool = options?.rarTool or RAR_TOOL 
    @debugMode = options?.debugMode or false
    @viewTool = options?.viewTool or VIEW_TOOL
    @faultTolerant = options?.faultTolerant or true
    @_loadedList = false
    @names =  []

    if not @archiveName
       err = new Error 'Must provide a filename.'
       if not @faultTolerant
         throw err
       else
         console?.log? err.toString()
            
    if not isRarFile @archiveName
      err = new Error "#{@archiveName} is not a RAR archive"
      if not @faultTolerant
        throw err
      else
        console?.log? err.toString()
    @on 'ready', (who) =>
      console?.log? who.toString() if who.debugMode
    @_loadNames()
    .then(
      ((readStream) =>
        @names = (f.replace('\r', '') for f in readStream.split '\n' when (f and f isnt 'undefined'))
        @_loadedList = true
        @
      ),
      ((err) =>
        if not @faultTolerant
          console?.log? "Throwing error #{err.toString()} produced while loading names from the RAR archive" if @debugMode
          throw err
        else
          console?.log? err.toString()
      )
    )
    .then(
      (self) =>
        self.emit 'ready', self
    )

  _loadNames: () =>
     params = "#{LIST_PARAMS.join ' '} \"#{@archiveName}\""
     executable = "\"#{@rarTool}\" #{params}"
     console?.log? "Running << #{executable} >>" if @debugMode
     deferred = _when.defer()
     exec executable, encoding: "utf8", maxBuffer: MAX_BUFFER_SIZE, (err, stdout, stderr) =>
       if err
         deferred.reject err
       else
         deferred.resolve stdout
     deferred.promise
     
     
  readStream: (filename, options) =>
    params =  (p for p in EXTRACT_PARAMS)
    params.push "#{@archiveName}"
    params.push "#{filename}"
    console?.log? "Running << #{@rarTool} #{params} >>" if @debugMode
    unrar = spawn "#{@rarTool}", params
    unrar.stdout.setEncoding 'binary'
    @emit 'readStream', unrar.stdout unless options?.silent
    console?.log? 'readStream EVENT' if @debugMode
    return unrar.stdout

  readFile: (filename, cb, options = encoding: 'binary') =>
    if cb and cb.constructor.name is 'Object'
      options = cb
    ( =>
        deferred = _when.defer()
        fdata = ''
        rStream = @readStream filename
        rStream.on 'error', (err) -> deferred.reject err
        rStream.on 'data', (chunk) -> fdata += chunk
        rStream.on 'end', () -> deferred.resolve fdata
        deferred.promise
    )()
    .then(
      ((data) =>
         bdata = new Buffer(data, options?.encoding or 'binary')
         @emit 'readFile:data', bdata unless options?.silent
         console?.log? 'readFile:data EVENT' if @debugMode
         if cb and cb.constructor.name is 'Function'
           cb null, bdata
         bdata
      ),
      ((err) =>
         @emit 'readFile:error', err unless options?.silent
         console?.log? "readFile:error - #{err.toString()}" if @debugMode 
         if cb and cb.constructor.name is 'Function'
           cb err, null
         err
      )
    )

  pipe: (filename, outStream, options = end: true, encoding: 'binary') =>
    if filename.constructor.name is 'Number'
      filename = @names[filename]
    if not filename
      err = new Error 'Wrong archive file'
      @emit 'pipe:error', err
      console?.log? "pipe:error - #{err.toString()}" if @debugMode
      if not @faultTolerant 
        throw err
    if (not outStream) or (not outStream.write) or (outStream.write.constructor.name isnt 'Function')
      err = new Error 'A writable stream must be provided'
      @emit 'pipe:error', err
      console?.log? "pipe:error - #{err.toString()}" if @debugMode 
      if not @faultTolerant
        throw err
    @readFile(filename)
    .then((data) =>
      if data.length is 0
        err = new Error 'File does not exist in the archive'
        @emit 'pipe:error', err
        console?.log? "pipe:error - #{err.toString()}" if @debugMode
        if not @faultTolerant 
          throw err
      outStream.write data, options?.encoding or 'binary'
      outStream.end() unless not options?.end
      @emit 'pipe:data', outStream, data unless options?.silent
      console?.log? "pipe:data EVENT" if @debugMode 
      data
    )    

  showFile: (filename) =>
    @readFile filename, (err, data) =>
      if err
        console?.log? err.toString()
        return
      fs.writeFileSync filename, data, 'binary'
      console?.log? "Length of extracted data: #{data.length}"
      try
       show  = spawn  @viewTool, [filename]
      catch e
        console?.log? e.toString()

  length: =>
    @names.length
    
  toString: () =>
      JSON.stringify names: @names, length: @length()
 

module.exports = {VERSION, isRarFile, RarFile}


