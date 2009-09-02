Dir[File.dirname(__FILE__) + "/tasks/*.rake"].each { |file| load(file) }

GithubGem::RakeTasks.new(:gem)
 
task :default => "spec:specdoc"