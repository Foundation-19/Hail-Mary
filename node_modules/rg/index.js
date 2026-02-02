#!/usr/bin/env node

var fs = require('fs')
var Stream = require('stream')
var argv = process.argv[2]

var package = function (template) {
  var pack = fs.existsSync(process.cwd() + '/package.json')
  if (pack) {
    var p = require(process.cwd() + '/package.json')
    var opts = {}
    opts.module_name = p.name || ''
    opts.synopsis = p.description || ''
    opts.license = p.license || ''
    Object.keys(opts).forEach(function (val) {
      template = template.replace(new RegExp('{{' + val + '}}', 'g'), opts[val])
    })
  }
 
  return template
}

var readbuffer = ''
var template = new Stream
template.writable = true
template.readable = true

template.write = function (buf) {
  readbuffer += buf
}

template.destroy = function () {
  template.writable = false
}

template.end = function () {
  this.emit('data', package(readbuffer))
}

var rg = function () {
  fs.exists('./README.md', function (exists) {
    if (exists && argv !== '-f') {
      console.log('README.md already exists. run with -f to overwrite')
      return
    }
    else {
      var readme = fs.createWriteStream(process.cwd() + '/README.md')
      fs.createReadStream(__dirname + '/r.md').pipe(template).pipe(readme)
    }
  })
}

rg()