require 'rubygems'
require 'hoe'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), "lib")

require 'rkelly/constants'

GENERATED_PARSER = "lib/rkelly/generated_parser.rb"

Hoe.new('js2fbjs', RKelly::VERSION) do |p|
  p.rubyforge_name  = 'js2fbjs'
  p.author          = 'Richard Jordan'
  p.email           = 'none'
  p.summary         = "Js2Fbjs parses JavaScript, returns a parse tree, and rewrites it into Facebook JavaScript."
  p.clean_globs     = [GENERATED_PARSER]
end

file GENERATED_PARSER => "lib/parser.y" do |t|
  if ENV['DEBUG']
    sh "racc -g -v -o #{t.name} #{t.prerequisites.first}"
  else
    sh "racc -o #{t.name} #{t.prerequisites.first}"
  end
end

task :parser => GENERATED_PARSER

# make sure the parser's up-to-date when we test
Rake::Task[:test].prerequisites << :parser
Rake::Task[:check_manifest].prerequisites << :parser
