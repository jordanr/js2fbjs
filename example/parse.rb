$: << 'lib'

require 'js2fbjs'
require 'js2fbjs/fbjs_rewriter'

#filename = ARGV[0]
filename = 'example/test.js'
jsfile = File.open(filename).read


p Js2Fbjs::Parser.new.parse(jsfile)

puts Js2Fbjs::FbjsRewriter.translate(jsfile)
#puts Js2Fbjs::JsProcessor.translate(jsfile)

