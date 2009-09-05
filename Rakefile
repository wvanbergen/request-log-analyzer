Dir[File.dirname(__FILE__) + "/tasks/*.rake"].each { |file| load(file) }

# Create rake tasks for a gem manages by github. The tasks are created in the
# gem namespace
GithubGem::RakeTasks.new(:gem)

# Set the RSpec runner with specdoc output as default task.
task :default => "spec:specdoc"
