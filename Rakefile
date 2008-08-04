require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

GENERATED_PARSER = "lib/js2fbjs/generated_parser.rb"

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the Js2Fbjs plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
Rake::Task[:test].prerequisites << :parser

desc 'Generate documentation for the Js2Fbjs plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Js2Fbjs'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.txt')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc 'Make sure the parser is up-to-date'
task :parser => GENERATED_PARSER
file GENERATED_PARSER => "lib/parser.y" do |t|
  if ENV['DEBUG']
    sh "racc -g -v -o #{t.name} #{t.prerequisites.first}"
  else
    sh "racc -o #{t.name} #{t.prerequisites.first}"
  end
end

desc "Removing generated parser"
task :clean do
  sh "rm #{GENERATED_PARSER}"
end
