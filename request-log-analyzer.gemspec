Gem::Specification.new do |s|
  s.name    = 'request-log-analyzer'
  s.version = "1.2.7"
  s.date    = "2009-09-02"
  
  s.rubyforge_project = 'r-l-a'
  
  s.bindir             = 'bin'
  s.executables        = ['request-log-analyzer']
  s.default_executable = 'request-log-analyzer'
  
  s.summary     = "A command line tool to analyze request logs for Rails, Merb and other application servers"
  s.description = <<-eos
    Request log analyzer's purpose is to find ot how your web application is being used and to focus your optimization efforts.
    This tool will parse all requests in the application's log file and aggregate the information. Once it is finished parsing 
    the log file(s), it will show the requests that take op most server time using various metrics. It can also insert all 
    parsed request information into a database so you can roll your own analysis. It supports Rails- and Merb-based applications 
    out of the box, but file formats of other applications can easily be supported by supplying an easy to write log file format 
    definition.
  eos
  
  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']
  
  s.requirements << "To use the database inserter, ActiveRecord and an appropriate database adapter are required."
  
  s.add_development_dependency('rspec', '>= 1.2.4')
  s.add_development_dependency('git',   '>= 1.1.0')
  
  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = ['willem@railsdoctors.com', 'bart@railsdoctors.com']
  s.homepage = 'http://railsdoctors.com'

  s.files      = %w(spec/unit/filter/anonymize_filter_spec.rb lib/request_log_analyzer/line_definition.rb lib/request_log_analyzer/output/html.rb lib/request_log_analyzer/controller.rb spec/fixtures/rails_22_cached.log lib/request_log_analyzer/file_format/rails_development.rb spec/lib/macros.rb spec/fixtures/merb_prefixed.log tasks/request_log_analyzer.rake spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/apache_format_spec.rb spec/integration/command_line_usage_spec.rb spec/fixtures/decompression.log.bz2 lib/request_log_analyzer/log_processor.rb lib/request_log_analyzer/tracker.rb lib/request_log_analyzer/filter.rb spec/fixtures/rails_unordered.log bin/request-log-analyzer request-log-analyzer.gemspec DESIGN.rdoc spec/unit/filter/timespan_filter_spec.rb lib/request_log_analyzer/filter/field.rb lib/request_log_analyzer/tracker/frequency.rb spec/fixtures/decompression.log.gz spec/fixtures/decompression.log spec/lib/matchers.rb spec/fixtures/test_order.log lib/request_log_analyzer/output/fixed_width.rb lib/request_log_analyzer/filter/anonymize.rb spec/lib/testing_format.rb lib/request_log_analyzer/tracker/timespan.rb lib/request_log_analyzer/aggregator.rb lib/cli/progressbar.rb README.rdoc spec/fixtures/merb.log lib/request_log_analyzer/tracker/hourly_spread.rb .gitignore spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/duration_tracker_spec.rb lib/request_log_analyzer/aggregator/echo.rb spec/unit/controller/log_processor_spec.rb spec/spec_helper.rb lib/request_log_analyzer.rb Rakefile spec/unit/filter/filter_spec.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/file_format/rails.rb spec/fixtures/test_language_combined.log spec/fixtures/decompression.tar.gz spec/unit/filter/field_filter_spec.rb spec/spec.opts lib/request_log_analyzer/aggregator/database.rb lib/request_log_analyzer/filter/timespan.rb lib/request_log_analyzer/source/log_parser.rb spec/fixtures/decompression.tgz spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/fixtures/apache.log spec/fixtures/header_and_footer.log lib/cli/tools.rb lib/request_log_analyzer/file_format/merb.rb spec/fixtures/multiple_files_1.log spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/line_definition_spec.rb lib/request_log_analyzer/source.rb lib/request_log_analyzer/request.rb spec/unit/controller/controller_spec.rb lib/request_log_analyzer/output.rb lib/request_log_analyzer/file_format/apache.rb spec/lib/helpers.rb spec/fixtures/rails_1x.log spec/lib/mocks.rb spec/fixtures/decompression.log.zip spec/unit/source/request_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/aggregator/database_spec.rb spec/fixtures/test_file_format.log lib/request_log_analyzer/source/database.rb tasks/github-gem.rake lib/request_log_analyzer/tracker/duration.rb lib/request_log_analyzer/file_format.rb spec/unit/aggregator/summarizer_spec.rb spec/fixtures/rails_22.log spec/fixtures/multiple_files_2.log spec/fixtures/syslog_1x.log LICENSE spec/unit/tracker/frequency_tracker_spec.rb spec/unit/file_format/rails_format_spec.rb lib/cli/command_line_arguments.rb)
  s.test_files = %w(spec/unit/filter/anonymize_filter_spec.rb spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/apache_format_spec.rb spec/integration/command_line_usage_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/filter/filter_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/controller/controller_spec.rb spec/unit/source/request_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/aggregator/database_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/file_format/rails_format_spec.rb)
end