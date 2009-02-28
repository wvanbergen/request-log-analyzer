Gem::Specification.new do |s|
  s.name    = 'request-log-analyzer'
  s.version = '1.1.6'
  s.date    = '2009-02-28'
  
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
  
  s.files = %w(DESIGN HACKING LICENSE README.rdoc Rakefile bin bin/request-log-analyzer lib lib/cli lib/cli/command_line_arguments.rb lib/cli/progressbar.rb lib/cli/tools.rb lib/request_log_analyzer lib/request_log_analyzer.rb lib/request_log_analyzer/aggregator lib/request_log_analyzer/aggregator.rb lib/request_log_analyzer/aggregator/database.rb lib/request_log_analyzer/aggregator/echo.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/controller.rb lib/request_log_analyzer/file_format lib/request_log_analyzer/file_format.rb lib/request_log_analyzer/file_format/merb.rb lib/request_log_analyzer/file_format/rails.rb lib/request_log_analyzer/file_format/rails_development.rb lib/request_log_analyzer/filter lib/request_log_analyzer/filter.rb lib/request_log_analyzer/filter/anonymize.rb lib/request_log_analyzer/filter/field.rb lib/request_log_analyzer/filter/timespan.rb lib/request_log_analyzer/line_definition.rb lib/request_log_analyzer/log_processor.rb lib/request_log_analyzer/output lib/request_log_analyzer/output.rb lib/request_log_analyzer/output/fixed_width.rb lib/request_log_analyzer/output/html.rb lib/request_log_analyzer/request.rb lib/request_log_analyzer/source lib/request_log_analyzer/source.rb lib/request_log_analyzer/source/database.rb lib/request_log_analyzer/source/log_parser.rb lib/request_log_analyzer/tracker lib/request_log_analyzer/tracker.rb lib/request_log_analyzer/tracker/duration.rb lib/request_log_analyzer/tracker/frequency.rb lib/request_log_analyzer/tracker/hourly_spread.rb lib/request_log_analyzer/tracker/timespan.rb spec spec/fixtures spec/fixtures/merb.log spec/fixtures/multiple_files_1.log spec/fixtures/multiple_files_2.log spec/fixtures/rails_1x.log spec/fixtures/rails_22.log spec/fixtures/rails_22_cached.log spec/fixtures/rails_unordered.log spec/fixtures/syslog_1x.log spec/fixtures/test_file_format.log spec/fixtures/test_language_combined.log spec/fixtures/test_order.log spec/integration spec/integration/command_line_usage_spec.rb spec/lib spec/lib/helper.rb spec/lib/mocks.rb spec/lib/testing_format.rb spec/spec_helper.rb spec/unit spec/unit/aggregator spec/unit/aggregator/database_inserter_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/controller spec/unit/controller/controller_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/file_format spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/rails_format_spec.rb spec/unit/filter spec/unit/filter/anonymize_filter_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/source spec/unit/source/log_parser_spec.rb spec/unit/source/request_spec.rb spec/unit/tracker spec/unit/tracker/duration_tracker_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/tracker_api_test.rb tasks tasks/github-gem.rake tasks/request_log_analyzer.rake)
  s.test_files = %w(spec/integration/command_line_usage_spec.rb spec/unit/aggregator/database_inserter_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/controller/controller_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/rails_format_spec.rb spec/unit/filter/anonymize_filter_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/source/request_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/tracker/timespan_tracker_spec.rb)
end