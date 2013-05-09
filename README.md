# node-rarfile
      
Utility for handling rarfile archives using [node](http://nodejs.org).



## Example

    var rarfile = require('rarfile');
    var rf = new rarfile.RarFile('./test/test.cbr');
    console.log(rf.toString());
      // { names: [ '0.jpg', '2.jpg']}
       
    rf.readFile('0.jpg', function(err, fdata) {
      console.log("File 0.jpg is " + fdata.length + " bytes long.");
    });


## Depends

node-rarfile 0.1.x depends on node v0.8 and above

node-rarfile depends on the free unrar tool being in the path, as all
its inner workings (with the exception of isRarFile function) relay on
spawning unrar as a child process. As such, it's guaranteed to work on
*nix systems which have unrar installed. Should work on Windows provided
unrar is installed and it's executable is in the path. This hasn't been tested, though

## Installation

Install via npm:

    npm install rarfile

## API

node-rarfile module exports an object which provides 2 properties
* isRarFile function, which may be used to test if a file is RAR compressed
* RarFile object, which must be instantiated with a RAR file path, otherwise will throw an error, 
  and which provides the following properties:
    names: an array containing the names of the archived files
    readFile: main function, must be called with two parameters: 1) Name of a file within the archive 2) A callback function meant to
    handle the file data.
    readStream: called with the file which data will be retrieved, returns the output stream of unrar child process, which may be piped
    to another stream or whatever use you see fit. There are some issues remaining for binary data (i.e. images)
    
## Motivation

For one thing, I couldn't find a node.js unrar utility along the lines of [node-zipfile](https://github.com/springmeyer/node-zipfile). 
Thought one should be available.
It's worth noting though, that in spite of trying to make an API as close as was possible to the aforementioned, the inner workings of both
are very different. node-zipfile is a much more complete piece of software, as you can easily figure out by examining the source codes of both.
node-rarfile is just a thin wrapper around unrar, anyway I hope it may be useful. 
    

## License

  MIT, see LICENSE
