module.exports =  ->
  RarFile = require('../src/index').RarFile
  fs = require 'fs'
  rf = new RarFile 'test.cbr'
  ostr = fs.createWriteStream 'x.jpg'
  rf.pipe '0.jpg', ostr
  {RarFile, fs, rf, ostr}



