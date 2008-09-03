require 'rubygems'

load 'test/tasks.rake'
 
desc 'Default: run unit tests.'
task :default => :test


namespace :gem do

  desc "Sets the version and date of the gem"
  task :spec_version do
    
    require 'date'
    
    new_version = ENV['VERSION']
    raise "VERSION is required" unless /\d+(\.\d+)*/ =~ new_version
    
    spec_file = Dir['*.gemspec'].first
    
    spec = File.read(spec_file)
    spec.gsub!(/^(\s*s\.version\s*=\s*)('|")(.+)('|")(\s*)$/) { "#{$1}'#{new_version}'#{$5}" }
    spec.gsub!(/^(\s*s\.date\s*=\s*)('|")(.+)('|")(\s*)$/) { "#{$1}'#{Date.today.strftime('%Y-%m-%d')}'#{$5}" }    
    File.open(spec_file, 'w') { |f| f << spec }
  end
  
  task :version => [:spec_version] do
    
    new_version = ENV['VERSION']
    raise "VERSION is required" unless /\d+(\.\d+)*/ =~ new_version
        
    sh "git add request-log-analyzer.gemspec"
    sh "git commit -m \"Set gem version to #{new_version}\""
    sh "git push origin"    
    sh "git tag -a \"request-log-analyzer-#{new_version}\" -m \"Tagged version #{new_version}\""
    sh "git push --tags"
  end

  desc "Builds a ruby gem for request-log-analyzer"
  task :build => [:manifest] do
    system %[gem build request-log-analyzer.gemspec]
  end

  desc %{Update ".manifest" with the latest list of project filenames. Respect\
  .gitignore by excluding everything that git ignores. Update `files` and\
  `test_files` arrays in "*.gemspec" file if it's present.}
  task :manifest do
    list = Dir['**/*'].sort
    spec_file = Dir['*.gemspec'].first
    list -= [spec_file] if spec_file
  
    File.read('.gitignore').each_line do |glob|
      glob = glob.chomp.sub(/^\//, '')
      list -= Dir[glob]
      list -= Dir["#{glob}/**/*"] if File.directory?(glob) and !File.symlink?(glob)
      puts "excluding #{glob}"
    end
 
    if spec_file
      spec = File.read spec_file
      spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
        assignment = $1
        bunch = $2 ? list.grep(/^test.*_test\.rb$/) : list
        '%s%%w(%s)' % [assignment, bunch.join(' ')]
      end
      
      File.open(spec_file,   'w') {|f| f << spec }
    end
    File.open('.manifest', 'w') {|f| f << list.join("\n") }
  end
end