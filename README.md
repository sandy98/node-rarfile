# node-rarfile
      
Utility for handling rarfile archives using [node](http://nodejs.org).



## Example

    var rarfile = require('rarfile');
    var rf = new rarfile.RarFile('./test/test.cbr');
    console.log(rf.toString());
      // { names: [ '0.jpg', '2.jpg']}
    
    //readFile function
    rf.readFile('0.jpg', function(err, fdata) {
      console.log("File 0.jpg is " + fdata.length + " bytes long.");
    });

    //pipe function. New in v0.1.4
    var fs = require('fs');
    var outfile = fs.createWriteStream('2_copy.jpg');
    rf.pipe('2.jpg', outfile);
    });


## Depends

 * node v0.8 and above

 * unrar free tool being in the path, as all
its inner workings (with the exception of isRarFile function) relay on
spawning unrar as a child process. As such, it's guaranteed to work on
<strong>*nix</strong> systems which have unrar installed. Should work on Windows provided
unrar is installed and it's executable is in the path. This has been recently tested,

 * [when](https://github.com/cujojs/when) asyncronous library.
 * 
## Installation

Install via npm:

    npm install rarfile

## API

node-rarfile module exports an object which exposes 3 properties

* <strong>VERSION</strong> Current module version.

* <strong>isRarFile</strong> function, which may be used to test if a file is RAR compressed

* <strong>RarFile</strong> object, which must be instantiated with a RAR file path, otherwise will throw an error, 
  and which features the following properties:

    * <strong>names</strong> (Object): an array containing the names of the archived files

    * <strong>readStream</strong> (Function): called with the file which data will be retrieved, returns the output stream of unrar child process, which may be piped
      to another stream or whatever use you see fit. There are some issues remaining for binary data (i.e. images)

    * <strong>readFile</strong> (Function): must be called with two parameters:

       * 1) Name of a file within the archive 

       * 2) A callback function meant to handle the file data.

    * <strong>pipe</strong> (Function): meant to make RarFile instances to behave like a ReadStream, it takes an additional (first)
      parameter, the name of the archived file to be piped, thus relegating the name of the write stream to the 
      second formal parameter. (See the previous example)
    
## Motivation

For one thing, I couldn't find a node.js unrar utility along the lines of 
[node-zipfile](https://github.com/springmeyer/node-zipfile), and thought one should be available.

It's worth noting though, that in spite of trying to make an API as close as was possible to the aforementioned, the inner workings of both
are very different. 

node-zipfile is a much more complete piece of software, as you can easily figure out by examining the source codes of both.
node-rarfile is just a thin wrapper around unrar, anyway I hope it may be useful. 
    

## License

  MIT, see LICENSE
