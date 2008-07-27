$: << 'lib'

require 'rkelly'
require 'fbjs_rewriter'

#filename = ARGV[0]
filename = 'example/test.js'
jsfile = File.open(filename).read

#puts FbjsRewriter.translate(jsfile)
#puts JsProcessor.translate(jsfile)

puts RKelly::Parser.new.parse(jsfile).to_sexp
