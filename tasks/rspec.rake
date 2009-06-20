require 'rake'
require 'spec/rake/spectask'

namespace :spec do 
  desc "Run all rspec with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|

    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', '"spec/*,gems/*"', '--rails']
  end
end