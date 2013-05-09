module.exports =  (filename = '0.jpg') ->
  RarFile = require('../src/index').RarFile
  fs = require 'fs'
  rf = new RarFile 'test.cbr'
  ostr = fs.createWriteStream filename
  rf.pipe filename, ostr
  {RarFile, fs, rf, ostr}



