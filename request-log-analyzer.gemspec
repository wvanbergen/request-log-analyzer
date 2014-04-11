# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'request_log_analyzer/version'

Gem::Specification.new do |gem|
  gem.name    = "request-log-analyzer"
  gem.rubyforge_project = 'r-l-a'

  gem.version = RequestLogAnalyzer::VERSION

  gem.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  gem.email    = ['willem@railsdoctors.com', 'bart@railsdoctors.com']
  gem.homepage = 'http://www.request-log-analyzer.com'
  gem.license  = "MIT"

  gem.summary     = "A command line tool to analyze request logs for Apache, Rails, Merb, MySQL and other web application servers"
  gem.description = <<-eos
    Request log analyzer's purpose is to find out how your web application is being used, how it performs and to
    focus your optimization efforts. This tool will parse all requests in the application's log file and aggregate the 
    information. Once it is finished parsing the log file(s), it will show the requests that take op most server time 
    using various metrics. It can also insert all parsed request information into a database so you can roll your own
    analysis. It supports Rails-, Merb- and Rack-based applications logs, Apache and Amazon S3 access logs and MySQL 
    slow query logs out of the box, but file formats of other applications can easily be supported by supplying an 
    easy to write log file format definition.
  eos

  gem.rdoc_options << '--title' << gem.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  gem.extra_rdoc_files = ['README.rdoc']

  gem.requirements << "To use the database inserter, ActiveRecord and an appropriate database adapter are required."
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec', '~> 2.14')
  gem.add_development_dependency('activerecord')
  if defined?(JRUBY_VERSION)
    gem.add_development_dependency('jdbc-sqlite3')
    gem.add_development_dependency('jdbc-mysql')
    gem.add_development_dependency('jdbc-postgres')
    gem.add_development_dependency('activerecord-jdbcsqlite3-adapter')
    gem.add_development_dependency('activerecord-jdbcmysql-adapter')
    gem.add_development_dependency('activerecord-jdbcpostgresql-adapter')
  else
    gem.add_development_dependency('sqlite3')
    gem.add_development_dependency('mysql2')
    gem.add_development_dependency('pg')
  end
  
  gem.files = `git ls-files`.split($/)
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})

  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.default_executable = 'request-log-analyzer'
  gem.bindir = 'bin'
  gem.require_paths = ["lib"]
end
