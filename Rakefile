require "bundler/gem_tasks"
require "rspec/core/rake_task"

Dir[File.dirname(__FILE__) + "/tasks/*.rake"].each { |file| load(file) }

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "./spec/**/*_spec.rb"
  task.rspec_opts = ['--color']
end

task :default => :spec
