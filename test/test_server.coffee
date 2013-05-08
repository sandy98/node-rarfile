#!/usr/bin/env coffee

Router = require 'node-simple-router'

RarFile = require('../lib/index').RarFile

http = require 'http'
router = Router(list_dir: true)

#
#Routes
#

rootPage =  (request, response) ->
  response.writeHead 200, 'Content-Type': 'text/html'
  response.end """
  <html>
    <head>
      <title>RAR Images Test</title>
    </head>
    <body>
      <div id="container" class="container">
        <div class="row" style="padding: 1em;">
          <a href="images/0"><img src="images/0" height="132px" width="88px" title="Cover" /><span style="padding-left: 1em;">Cover</span></a>
        </div>
        <div class="row" style="padding: 1em;">
          <a href="images/2"><img src="images/2" height="132px" width="88px" title="Page No 2" /><span style="padding-left: 1em;">Page No 2</span></a>
        </div>
    </body>
  </html> 
  """

router.get '/', rootPage
router.get '/index.html', rootPage

router.get "/images/:id", (request, response) ->
  rarFile = new RarFile './test.cbr'
  rarFile.readFile "#{request.params.id}.jpg", (err, fdata) ->
     if fdata.length
       response.writeHead 200, 'Content-Type': 'image/jpg'
       response.write fdata, 'binary'
     else
       response.writeHead 200, 'Content-Type': 'text/html'
       response.write '<h3 style="color: red; text-align: center;">Sorry, ain\'t got the image you\'re looking for</h3>'
     response.end()


#
#End of Routes
#


#Ok, just start the server!

argv = process.argv.slice 2

server = http.createServer router

server.on 'listening', ->
  addr = server.address() or {address: '0.0.0.0', port: argv[0] or 8000}
  router.log "Serving web content at " + addr.address + ":" + addr.port  

process.on "SIGINT", ->
  server.close()
  router.log ' '
  router.log "Server shutting up..."
  router.log ' '
  process.exit 0

server.listen if argv[0]? and not isNaN(parseInt(argv[0])) then parseInt(argv[0]) else 8000
