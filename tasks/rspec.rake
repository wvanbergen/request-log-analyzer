require 'rake'
require 'spec/rake/spectask'

namespace :spec do 
  desc "Run all rspec with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|

    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', '"spec/*,gems/*"', '--rails']
  end

  desc "Run all specs in spec directory (excluding plugin specs)"
  Spec::Rake::SpecTask.new(:fancy) do |t|
    t.spec_opts = ['--options', "\"spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
end

