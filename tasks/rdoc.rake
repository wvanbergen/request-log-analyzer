require 'rake/rdoctask'

namespace(:doc) do 
  desc 'Generate documentation for request-log-analyzer'
  Rake::RDocTask.new(:compile) do |rdoc|
    rdoc.rdoc_dir = 'doc'
    rdoc.title    = 'request-log-analyzer'
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README.rdoc')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
end