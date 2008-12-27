Gem::Specification.new do |s|
  s.name    = 'request-log-analyzer'
  s.version = '0.3.0'
  s.date    = '2008-12-27'
  
  s.bindir = 'bin'
  s.executables = ['request-log-analyzer']
  s.default_executable = 'request-log-analyzer'
  
  s.summary = "A command line tool to analyze Rails logs"
  s.description = "Rails log analyzer's purpose is to find what actions are best candidates for optimization. This tool will parse all requests in the Rails logfile and aggregate the information. Once it is finished parsing the log file, it will show the requests that take op most server time using various metrics."
  
  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = 'willem@vanbergen.org'
  s.homepage = 'http://github.com/wvanbergen/request-log-analyzer/wikis'
  
  s.files = %w(LICENSE README.textile Rakefile TODO bin bin/request-log-analyzer lib lib/base lib/base/summarizer.rb lib/bashcolorizer.rb lib/command_line lib/command_line/arguments.rb lib/command_line/exceptions.rb lib/command_line/flag.rb lib/merb_analyzer lib/merb_analyzer/summarizer.rb lib/rails_analyzer lib/rails_analyzer/summarizer.rb lib/rails_analyzer/virtual_mongrel.rb lib/request_log_analyzer lib/request_log_analyzer.rb lib/request_log_analyzer/aggregator lib/request_log_analyzer/aggregator/base.rb lib/request_log_analyzer/aggregator/database.rb lib/request_log_analyzer/aggregator/echo.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/controller.rb lib/request_log_analyzer/file_format lib/request_log_analyzer/file_format.rb lib/request_log_analyzer/file_format/merb.rb lib/request_log_analyzer/file_format/rails.rb lib/request_log_analyzer/log_parser.rb lib/request_log_analyzer/request.rb lib/ruby-progressbar lib/ruby-progressbar/progressbar.en.rd lib/ruby-progressbar/progressbar.ja.rd lib/ruby-progressbar/progressbar.rb output output/blockers.rb output/errors.rb output/hourly_spread.rb output/mean_db_time.rb output/mean_rendering_time.rb output/mean_time.rb output/most_requested.rb output/timespan.rb output/total_db_time.rb output/total_time.rb output/usage.rb spec spec/controller_spec.rb spec/database_inserter_spec.rb spec/fixtures spec/fixtures/merb.log spec/fixtures/multiple_files_1.log spec/fixtures/multiple_files_2.log spec/fixtures/rails_1x.log spec/fixtures/rails_22.log spec/fixtures/rails_22_cached.log spec/fixtures/rails_unordered.log spec/fixtures/syslog_1x.log spec/fixtures/test_file_format.log spec/fixtures/test_language_combined.log spec/fixtures/test_order.log spec/line_definition_spec.rb spec/log_parser_spec.rb spec/merb_format_spec.rb spec/rails_format_spec.rb spec/request_spec.rb spec/spec_helper.rb spec/summarizer_spec.rb tasks tasks/github-gem.rake tasks/request_log_analyzer.rake tasks/rspec.rake test test/base_summarizer_test.rb)
  s.test_files = %w(test/base_summarizer_test.rb)
end