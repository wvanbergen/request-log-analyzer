require 'rake/testtask'
 
desc 'Unit test request-log-analyzer.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.libs << 'test'
end