Gem::Specification.new do |s|
  s.name    = 'request-log-analyzer'
  s.version = '0.3.3'
  s.date    = '2008-12-28'
  
  s.bindir = 'bin'
  s.executables = ['request-log-analyzer', 'request-log-database']
  s.default_executable = 'request-log-analyzer'
  
  s.summary = "A command line tool to analyze Rails logs"
  s.description = "Rails log analyzer's purpose is to find what actions are best candidates for optimization. This tool will parse all requests in the Rails logfile and aggregate the information. Once it is finished parsing the log file, it will show the requests that take op most server time using various metrics."
  
  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = 'willem@vanbergen.org'
  s.homepage = 'http://github.com/wvanbergen/request-log-analyzer/wikis'
  
  s.files = %w(LICENSE README.textile Rakefile TODO bin bin/request-log-analyzer bin/request-log-database lib lib/base lib/base/log_parser.rb lib/base/record_inserter.rb lib/base/summarizer.rb lib/bashcolorizer.rb lib/command_line lib/command_line/arguments.rb lib/command_line/exceptions.rb lib/command_line/flag.rb lib/merb_analyzer lib/merb_analyzer/log_parser.rb lib/merb_analyzer/summarizer.rb lib/rails_analyzer lib/rails_analyzer/log_parser.rb lib/rails_analyzer/record_inserter.rb lib/rails_analyzer/summarizer.rb lib/ruby-progressbar lib/ruby-progressbar/progressbar.en.rd lib/ruby-progressbar/progressbar.ja.rd lib/ruby-progressbar/progressbar.rb output output/blockers.rb output/errors.rb output/hourly_spread.rb output/mean_db_time.rb output/mean_rendering_time.rb output/mean_time.rb output/most_requested.rb output/timespan.rb output/total_db_time.rb output/total_time.rb output/usage.rb tasks tasks/github-gem.rake tasks/request_log_analyzer.rake tasks/test.rake test test/base_summarizer_test.rb test/log_fragments test/log_fragments/fragment_1.log test/log_fragments/fragment_2.log test/log_fragments/fragment_3.log test/log_fragments/merb_1.log test/merb_log_parser_test.rb test/rails_log_parser_test.rb test/record_inserter_test.rb)
  s.test_files = %w(test/base_summarizer_test.rb test/merb_log_parser_test.rb test/rails_log_parser_test.rb test/record_inserter_test.rb)
end