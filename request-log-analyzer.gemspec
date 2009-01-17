Gem::Specification.new do |s|
  s.name    = 'request-log-analyzer'
  s.version = '1.0.3'
  s.date    = '2009-01-14'
  
  s.rubyforge_project = 'r-l-a'
  
  s.bindir = 'bin'
  s.executables = ['request-log-analyzer']
  s.default_executable = 'request-log-analyzer'
  
  s.summary = "A command line tool to analyze Rails logs"
  s.description = "Rails log analyzer's purpose is to find what actions are best candidates for optimization. This tool will parse all requests in the Rails logfile and aggregate the information. Once it is finished parsing the log file, it will show the requests that take op most server time using various metrics."
  
  s.has_rdoc = true
  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']
  
  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = 'willem@vanbergen.org'
  s.homepage = 'http://github.com/wvanbergen/request-log-analyzer/wikis'
  
  s.files = %w(DESIGN HACKING LICENSE README.textile Rakefile bin bin/request-log-analyzer lib lib/cli lib/cli/bashcolorizer.rb lib/cli/command_line_arguments.rb lib/cli/progressbar.rb lib/request_log_analyzer lib/request_log_analyzer.rb lib/request_log_analyzer/aggregator lib/request_log_analyzer/aggregator/base.rb lib/request_log_analyzer/aggregator/database.rb lib/request_log_analyzer/aggregator/echo.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/controller.rb lib/request_log_analyzer/file_format lib/request_log_analyzer/file_format.rb lib/request_log_analyzer/file_format/merb.rb lib/request_log_analyzer/file_format/rails.rb lib/request_log_analyzer/filter lib/request_log_analyzer/filter/anonimize.rb lib/request_log_analyzer/filter/base.rb lib/request_log_analyzer/filter/field.rb lib/request_log_analyzer/filter/timespan.rb lib/request_log_analyzer/line_definition.rb lib/request_log_analyzer/log_parser.rb lib/request_log_analyzer/log_processor.rb lib/request_log_analyzer/request.rb lib/request_log_analyzer/source lib/request_log_analyzer/source/base.rb lib/request_log_analyzer/source/log_file.rb lib/request_log_analyzer/tracker lib/request_log_analyzer/tracker/base.rb lib/request_log_analyzer/tracker/category.rb lib/request_log_analyzer/tracker/duration.rb lib/request_log_analyzer/tracker/hourly_spread.rb lib/request_log_analyzer/tracker/timespan.rb spec spec/controller_spec.rb spec/database_inserter_spec.rb spec/file_format_spec.rb spec/file_formats spec/file_formats/spec_format.rb spec/filter_spec.rb spec/fixtures spec/fixtures/merb.log spec/fixtures/multiple_files_1.log spec/fixtures/multiple_files_2.log spec/fixtures/rails_1x.log spec/fixtures/rails_22.log spec/fixtures/rails_22_cached.log spec/fixtures/rails_unordered.log spec/fixtures/syslog_1x.log spec/fixtures/test_file_format.log spec/fixtures/test_language_combined.log spec/fixtures/test_order.log spec/line_definition_spec.rb spec/log_parser_spec.rb spec/log_processor_spec.rb spec/merb_format_spec.rb spec/rails_format_spec.rb spec/request_spec.rb spec/spec_helper.rb spec/summarizer_spec.rb tasks tasks/github-gem.rake tasks/request_log_analyzer.rake tasks/rspec.rake)
  s.test_files = %w(spec/controller_spec.rb spec/database_inserter_spec.rb spec/file_format_spec.rb spec/filter_spec.rb spec/line_definition_spec.rb spec/log_parser_spec.rb spec/log_processor_spec.rb spec/merb_format_spec.rb spec/rails_format_spec.rb spec/request_spec.rb spec/summarizer_spec.rb)
end