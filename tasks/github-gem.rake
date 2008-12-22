require 'rubygems'
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
        
        desc "Builds a ruby gem for #{@name}"
        task(:build => [:manifest]) { build_task }
        
        desc "Installs the ruby gem for #{@name} locally"
        task(:install => [:build]) { install_task }
        
        desc "Uninstalls the ruby gem for #{@name} locally"
        task(:uninstall) { uninstall_task }             
        
        desc "Releases a new version of #{@name}"
        task(:release) { release_task } 
      end
    end
    

    
    protected 

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
        bunch = $2 ? list.grep(/^test.*_test\.rb$/) : list
        '%s%%w(%s)' % [assignment, bunch.join(' ')]
      end

      File.open(gemspec_file, 'w') { |f| f << spec }
      reload_gemspec!
    end
    
    def build_task
      sh "gem build #{gemspec_file}"
    end
    
    def install_task
      raise "#{name} .gem file not found" unless File.exist?("#{name}-#{specification.version}.gem")
      sh "gem install #{name}-#{specification.version}.gem"
    end
    
    def uninstall_task
      raise "#{name} .gem file not found" unless File.exist?("#{name}-#{specification.version}.gem")
      sh "gem uninstall #{name}"
    end    
    
    def release_task
      verify_clean_status('master')
      verify_version(ENV['VERSION'] || @specification.version)
      
      # update gemspec file
      self.gemspec_version = ENV['VERSION'] if Gem::Version.correct?(ENV['VERSION'])
      self.gemspec_date    = Date.today
      manifest_task      
      git_commit_file(gemspec_file, "Updated #{gemspec_file} for release of version #{@specification.version}") if git_modified?(gemspec_file)

      # create tag and push changes
      git_create_tag("#{@name}-#{@specification.version}", "Tagged version #{@specification.version}")
      git_push('origin', 'master', [:tags])
    end
  end
end

Rake::GithubGem.define_tasks!