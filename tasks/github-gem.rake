require 'rubygems'
require 'rubyforge'
require 'rake'
require 'rake/tasklib'
require 'date'

module Rake 
  
  class GithubGem < TaskLib
    
    attr_accessor :name
    attr_accessor :specification
   
    def self.define_tasks!
      gem_task_builder = Rake::GithubGem.new      
      gem_task_builder.register_all_tasks!
    end
    

    def initialize
      reload_gemspec!
    end

    def register_all_tasks!
      namespace(:gem) do
        desc "Updates the file lists for this gem"
        task(:manifest) { manifest_task }

        desc "Releases a new version of #{@name}"
        task(:build => [:manifest]) { build_task } 
        
        
        release_dependencies = [:check_clean_master_branch, :version, :build, :create_tag]
        release_dependencies.push 'doc:publish' if has_rdoc?
        release_dependencies.unshift 'test' if has_tests?
        release_dependencies.unshift 'spec' if has_specs?
                
        desc "Releases a new version of #{@name}"
        task(:release => release_dependencies) { release_task } 
        
        # helper task for releasing
        task(:check_clean_master_branch) { verify_clean_status('master') }
        task(:check_version) { verify_version(ENV['VERSION'] || @specification.version) }
        task(:version => [:check_version]) { set_gem_version! }
        task(:create_tag) { create_version_tag! }
      end
      
      # Register RDoc tasks
      if has_rdoc?
        require 'rake/rdoctask'
        
        namespace(:doc) do 
          desc 'Generate documentation for request-log-analyzer'
          Rake::RDocTask.new(:compile) do |rdoc|
            rdoc.rdoc_dir = 'doc'
            rdoc.title    = @name
            rdoc.options += @specification.rdoc_options
            rdoc.rdoc_files.include(@specification.extra_rdoc_files)
            rdoc.rdoc_files.include('lib/**/*.rb')
          end
          
          desc "Publish RDoc files for #{@name} to Github"
          task(:publish => :compile) do
            sh 'git checkout gh-pages'
            sh 'git pull origin gh-pages'
            sh 'cp -rf doc/* .'
            sh "git commit -am \"Publishing newest RDoc documentation for #{@name}\""
            sh "git push origin gh-pages"
            sh "git checkout master"
          end
        end
      end
    
      # Setup :spec task if RSpec files exist
      if has_specs?
        require 'spec/rake/spectask'

        desc "Run all specs for #{@name}"
        Spec::Rake::SpecTask.new(:spec) do |t|
          t.spec_files = FileList['spec/**/*_spec.rb']
        end
      end
      
      # Setup :test task if unit test files exist
      if has_tests?
        require 'rake/testtask'

        desc "Run all unit tests for #{@name}"
        Rake::TestTask.new(:test) do |t|
          t.pattern = 'test/**/*_test.rb'
          t.verbose = true
          t.libs << 'test'
        end
      end      
    end
    
    protected 

    def has_rdoc?
      @specification.has_rdoc
    end

    def has_specs?
      Dir['spec/**/*_spec.rb'].any?
    end
    
    def has_tests?
      Dir['test/**/*_test.rb'].any?
    end

    def reload_gemspec!
      raise "No gemspec file found!" if gemspec_file.nil?      
      spec = File.read(gemspec_file)
      @specification = eval(spec)
      @name = specification.name  
    end

    def run_command(command)
      lines = []
      IO.popen(command) { |f| lines = f.readlines }
      return lines
    end
    
    def git_modified?(file)
      return !run_command('git status').detect { |line| Regexp.new(Regexp.quote(file)) =~ line }.nil?
    end
    
    def git_commit_file(file, message, branch = nil)
      verify_current_branch(branch) unless branch.nil?
      if git_modified?(file)
        sh "git add #{file}"
        sh "git commit -m \"#{message}\""
      else
        raise "#{file} is not modified and cannot be committed!"
      end
    end
    
    def git_create_tag(tag_name, message)
      sh "git tag -a \"#{tag_name}\" -m \"#{message}\""
    end
    
    def git_push(remote = 'origin', branch = 'master', options = [])
      verify_clean_status(branch)
      options_str = options.map { |o| "--#{o}"}.join(' ')
      sh "git push #{options_str} #{remote} #{branch}"
    end
    
    def gemspec_version=(new_version)
      spec = File.read(gemspec_file)
      spec.gsub!(/^(\s*s\.version\s*=\s*)('|")(.+)('|")(\s*)$/) { "#{$1}'#{new_version}'#{$5}" }
      spec.gsub!(/^(\s*s\.date\s*=\s*)('|")(.+)('|")(\s*)$/) { "#{$1}'#{Date.today.strftime('%Y-%m-%d')}'#{$5}" }    
      File.open(gemspec_file, 'w') { |f| f << spec }
      reload_gemspec!      
    end
    
    def gemspec_date=(new_date)
      spec = File.read(gemspec_file)
      spec.gsub!(/^(\s*s\.date\s*=\s*)('|")(.+)('|")(\s*)$/) { "#{$1}'#{new_date.strftime('%Y-%m-%d')}'#{$5}" }    
      File.open(gemspec_file, 'w') { |f| f << spec }
      reload_gemspec!       
    end
    
    def gemspec_file 
      @gemspec_file ||= Dir['*.gemspec'].first
    end
    
    def verify_current_branch(branch)
      run_command('git branch').detect { |line| /^\* (.+)/ =~ line }
      raise "You are currently not working in the master branch!" unless branch == $1
    end
    
    def verify_clean_status(on_branch = nil)
      sh "git fetch"
      lines = run_command('git status')
      raise "You don't have the most recent version available. Run git pull first." if /^\# Your branch is behind/ =~ lines[1]
      raise "You are currently not working in the #{on_branch} branch!" unless on_branch.nil? || (/^\# On branch (.+)/ =~ lines.first && $1 == on_branch)
      raise "Your master branch contains modifications!" unless /^nothing to commit \(working directory clean\)/ =~ lines.last
    end
    
    def verify_version(new_version)
      newest_version = run_command('git tag').map { |tag| tag.split(name + '-').last }.compact.map { |v| Gem::Version.new(v) }.max
      raise "This version number (#{new_version}) is not higher than the highest tagged version (#{newest_version})" if !newest_version.nil? && newest_version >= Gem::Version.new(new_version.to_s)
    end
    
    def set_gem_version!
      # update gemspec file
      self.gemspec_version = ENV['VERSION'] if Gem::Version.correct?(ENV['VERSION'])
      self.gemspec_date    = Date.today
    end

    def manifest_task
      verify_current_branch('master')
      
      list = Dir['**/*'].sort
      list -= [gemspec_file]

      if File.exist?('.gitignore')
        File.read('.gitignore').each_line do |glob|
          glob = glob.chomp.sub(/^\//, '')
          list -= Dir[glob]
          list -= Dir["#{glob}/**/*"] if File.directory?(glob) and !File.symlink?(glob)
        end
      end
      
      # update the spec file
      spec = File.read(gemspec_file)
      spec.gsub! /^(\s* s.(test_)?files \s* = \s* )( \[ [^\]]* \] | %w\( [^)]* \) )/mx do
        assignment = $1
        bunch = $2 ? list.grep(/^(test.*_test\.rb|spec.*_spec.rb)$/) : list
        '%s%%w(%s)' % [assignment, bunch.join(' ')]
      end

      File.open(gemspec_file, 'w') { |f| f << spec }
      reload_gemspec!
    end
    
    def build_task
      sh "gem build #{gemspec_file}"
      Dir.mkdir('pkg') unless File.exist?('pkg')
      sh "mv #{name}-#{specification.version}.gem pkg/#{name}-#{specification.version}.gem" 
    end
    
    def install_task
      raise "#{name} .gem file not found" unless File.exist?("pkg/#{name}-#{specification.version}.gem")
      sh "gem install pkg/#{name}-#{specification.version}.gem"
    end
    
    def uninstall_task
      raise "#{name} .gem file not found" unless File.exist?("pkg/#{name}-#{specification.version}.gem")
      sh "gem uninstall #{name}"
    end    
    
    def create_version_tag!
      # commit the gemspec file
      git_commit_file(gemspec_file, "Updated #{gemspec_file} for release of version #{@specification.version}") if git_modified?(gemspec_file)

      # create tag and push changes
      git_create_tag("#{@name}-#{@specification.version}", "Tagged version #{@specification.version}")
      git_push('origin', 'master', [:tags])     
    end
    
    def release_task
      puts
      puts '------------------------------------------------------------'
      puts "Released #{@name} - version #{@specification.version}"
    end
  end
end

Rake::GithubGem.define_tasks!