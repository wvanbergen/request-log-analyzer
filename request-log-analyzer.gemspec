Gem::Specification.new do |s|
  s.name    = "request-log-analyzer"
  
  # Do not set the version and date field manually, this is done by the release script
  s.version = "1.4.0.1"
  s.date    = "2009-10-03"

  s.rubyforge_project = 'r-l-a'

  s.bindir             = 'bin'
  s.executables        = ['request-log-analyzer']
  s.default_executable = 'request-log-analyzer'

  s.summary     = "A command line tool to analyze request logs for Apache, Rails, Merb and other web application servers"
  s.description = <<-eos
    Request log analyzer's purpose is to find ot how your web application is being used and to focus your optimization efforts.
    This tool will parse all requests in the application's log file and aggregate the information. Once it is finished parsing
    the log file(s), it will show the requests that take op most server time using various metrics. It can also insert all
    parsed request information into a database so you can roll your own analysis. It supports Rails- and Merb-based applications
    and Apache access log files out of the box, but file formats of other applications can easily be supported by supplying an
    easy to write log file format definition.
  eos

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.requirements << "To use the database inserter, ActiveRecord and an appropriate database adapter are required."

  s.add_development_dependency('rspec', '>= 1.2.4')
  s.add_development_dependency('git',   '>= 1.1.0')

  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = ['willem@railsdoctors.com', 'bart@railsdoctors.com']
  s.homepage = 'http://railsdoctors.com'

  # The files and test_files directives are set automatically by the release script.
  # Do not change them by hand, but make sure to add the files to the git repository.
  s.files      = %w(spec/unit/filter/anonymize_filter_spec.rb spec/fixtures/rails_22_cached.log lib/request_log_analyzer/line_definition.rb lib/request_log_analyzer/output/html.rb lib/request_log_analyzer/controller.rb spec/lib/macros.rb lib/request_log_analyzer/file_format/rails_development.rb spec/fixtures/apache_combined.log spec/fixtures/apache_common.log spec/fixtures/merb_prefixed.log lib/request_log_analyzer/file_format/amazon_s3.rb tasks/request_log_analyzer.rake spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/apache_format_spec.rb spec/integration/command_line_usage_spec.rb lib/request_log_analyzer/database.rb spec/fixtures/decompression.log.bz2 spec/fixtures/rails_unordered.log lib/request_log_analyzer/log_processor.rb lib/request_log_analyzer/tracker.rb lib/request_log_analyzer/filter.rb bin/request-log-analyzer request-log-analyzer.gemspec DESIGN.rdoc spec/unit/filter/timespan_filter_spec.rb spec/unit/aggregator/database_inserter_spec.rb spec/lib/matchers.rb lib/request_log_analyzer/filter/field.rb lib/request_log_analyzer/tracker/frequency.rb spec/fixtures/decompression.log.gz spec/fixtures/decompression.log spec/lib/testing_format.rb spec/fixtures/test_order.log spec/fixtures/rails.db lib/request_log_analyzer/output/fixed_width.rb lib/request_log_analyzer/filter/anonymize.rb lib/request_log_analyzer/tracker/timespan.rb lib/request_log_analyzer/database/base.rb lib/request_log_analyzer/aggregator.rb spec/unit/request_spec.rb lib/cli/progressbar.rb lib/request_log_analyzer/mailer.rb README.rdoc lib/request_log_analyzer/database/warning.rb spec/fixtures/merb.log lib/request_log_analyzer/tracker/hourly_spread.rb .gitignore spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/file_format/amazon_s3_format_spec.rb spec/integration/scout_spec.rb lib/request_log_analyzer/aggregator/echo.rb spec/unit/mailer_spec.rb spec/unit/controller/log_processor_spec.rb spec/spec_helper.rb lib/request_log_analyzer.rb spec/database.yml Rakefile lib/request_log_analyzer/database/connection.rb spec/unit/filter/filter_spec.rb spec/fixtures/test_language_combined.log lib/request_log_analyzer/aggregator/database_inserter.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/file_format/rack.rb lib/request_log_analyzer/database/source.rb lib/request_log_analyzer/file_format/rails.rb spec/fixtures/decompression.tar.gz spec/unit/tracker/traffic_tracker_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/database/base_class_spec.rb lib/request_log_analyzer/filter/timespan.rb lib/request_log_analyzer/source/log_parser.rb spec/fixtures/decompression.tgz spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/fixtures/header_and_footer.log lib/cli/tools.rb lib/request_log_analyzer/file_format/merb.rb spec/fixtures/multiple_files_1.log spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/line_definition_spec.rb lib/request_log_analyzer/source.rb lib/request_log_analyzer/request.rb lib/cli/database_console.rb spec/unit/database/connection_spec.rb spec/unit/controller/controller_spec.rb spec/lib/mocks.rb spec/lib/helpers.rb spec/fixtures/rails_1x.log lib/cli/database_console_init.rb lib/request_log_analyzer/output.rb lib/request_log_analyzer/file_format/apache.rb spec/fixtures/decompression.log.zip spec/unit/source/log_parser_spec.rb spec/integration/scouts_custom_output.rb spec/fixtures/test_file_format.log tasks/github-gem.rake spec/unit/database/database_spec.rb spec/integration/munin_plugins_rails_spec.rb lib/request_log_analyzer/tracker/duration.rb lib/request_log_analyzer/tracker/traffic.rb lib/request_log_analyzer/file_format.rb spec/unit/aggregator/summarizer_spec.rb spec/fixtures/syslog_1x.log spec/fixtures/rails_22.log lib/request_log_analyzer/database/request.rb spec/fixtures/multiple_files_2.log LICENSE lib/request_log_analyzer/source/database_loader.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/file_format/rails_format_spec.rb lib/cli/command_line_arguments.rb)
  s.test_files = %w(spec/unit/filter/anonymize_filter_spec.rb spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/apache_format_spec.rb spec/integration/command_line_usage_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/aggregator/database_inserter_spec.rb spec/unit/request_spec.rb spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/file_format/amazon_s3_format_spec.rb spec/integration/scout_spec.rb spec/unit/mailer_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/filter/filter_spec.rb spec/unit/tracker/traffic_tracker_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/database/base_class_spec.rb spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/database/connection_spec.rb spec/unit/controller/controller_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/database/database_spec.rb spec/integration/munin_plugins_rails_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/file_format/rails_format_spec.rb)
end