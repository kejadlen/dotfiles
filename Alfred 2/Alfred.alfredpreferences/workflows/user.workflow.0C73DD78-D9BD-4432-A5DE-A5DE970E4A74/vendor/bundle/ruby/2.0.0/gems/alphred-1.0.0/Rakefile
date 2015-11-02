require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
end

task :console do
  require "bundler/setup"
  require "alphred"

  require "pry"
  Pry.start
end

task :default => :test
