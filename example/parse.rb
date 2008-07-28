$: << 'lib'

require 'js2fbjs'
require 'js2fbjs/fbjs_rewriter'

#filename = ARGV[0]
filename = 'example/test.js'
jsfile = File.open(filename).read

#puts FbjsRewriter.translate(jsfile)

p Js2Fbjs::Parser.new.parse(jsfile)

puts JsProcessor.translate(jsfile)

