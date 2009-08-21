require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rake/rdoctask'

desc 'Default: run acts_as_ordered_tree unit tests.'
task :default => :test

desc 'Test the acts_as_ordered_tree plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_ordered_tree plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsOrderedTree'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('lib/person.rb')
end
