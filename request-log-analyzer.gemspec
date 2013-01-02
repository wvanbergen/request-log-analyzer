Gem::Specification.new do |s|
  s.name    = "request-log-analyzer"
  
  # Do not set the version and date field manually, this is done by the release script
  s.version = "1.12.7"
  s.date    = "2013-01-02"

  s.rubyforge_project = 'r-l-a'

  s.bindir             = 'bin'
  s.executables        = ['request-log-analyzer']
  s.default_executable = 'request-log-analyzer'

  s.summary     = "A command line tool to analyze request logs for Apache, Rails, Merb, MySQL and other web application servers"
  s.description = <<-eos
    Request log analyzer's purpose is to find out how your web application is being used, how it performs and to
    focus your optimization efforts. This tool will parse all requests in the application's log file and aggregate the 
    information. Once it is finished parsing the log file(s), it will show the requests that take op most server time 
    using various metrics. It can also insert all parsed request information into a database so you can roll your own
    analysis. It supports Rails-, Merb- and Rack-based applications logs, Apache and Amazon S3 access logs and MySQL 
    slow query logs out of the box, but file formats of other applications can easily be supported by supplying an 
    easy to write log file format definition.
  eos

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.requirements << "To use the database inserter, ActiveRecord and an appropriate database adapter are required."

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.8')

  s.add_development_dependency('activerecord')

  if defined?(JRUBY_VERSION)
    s.add_development_dependency('jdbc-sqlite3')
    s.add_development_dependency('activerecord-jdbcsqlite3-adapter')
  else
    s.add_development_dependency('sqlite3')
  end
  
  s.authors  = ['Willem van Bergen', 'Bart ten Brinke']
  s.email    = ['willem@railsdoctors.com', 'bart@railsdoctors.com']
  s.homepage = 'http://railsdoctors.com'

  # The files and test_files directives are set automatically by the release script.
  # Do not change them by hand, but make sure to add the files to the git repository.
  s.files      = %w(.gitignore .infinity_test .travis.yml DESIGN.rdoc Gemfile LICENSE README.rdoc Rakefile bin/request-log-analyzer lib/cli/command_line_arguments.rb lib/cli/database_console.rb lib/cli/database_console_init.rb lib/cli/progressbar.rb lib/cli/tools.rb lib/other/ordered_hash.rb lib/request_log_analyzer.rb lib/request_log_analyzer/aggregator.rb lib/request_log_analyzer/aggregator/database_inserter.rb lib/request_log_analyzer/aggregator/echo.rb lib/request_log_analyzer/aggregator/summarizer.rb lib/request_log_analyzer/controller.rb lib/request_log_analyzer/database.rb lib/request_log_analyzer/database/base.rb lib/request_log_analyzer/database/connection.rb lib/request_log_analyzer/database/request.rb lib/request_log_analyzer/database/source.rb lib/request_log_analyzer/database/warning.rb lib/request_log_analyzer/file_format.rb lib/request_log_analyzer/file_format/amazon_s3.rb lib/request_log_analyzer/file_format/apache.rb lib/request_log_analyzer/file_format/delayed_job.rb lib/request_log_analyzer/file_format/delayed_job2.rb lib/request_log_analyzer/file_format/delayed_job21.rb lib/request_log_analyzer/file_format/delayed_job3.rb lib/request_log_analyzer/file_format/haproxy.rb lib/request_log_analyzer/file_format/merb.rb lib/request_log_analyzer/file_format/mysql.rb lib/request_log_analyzer/file_format/nginx.rb lib/request_log_analyzer/file_format/oink.rb lib/request_log_analyzer/file_format/postgresql.rb lib/request_log_analyzer/file_format/rack.rb lib/request_log_analyzer/file_format/rails.rb lib/request_log_analyzer/file_format/rails3.rb lib/request_log_analyzer/file_format/rails_development.rb lib/request_log_analyzer/file_format/w3c.rb lib/request_log_analyzer/filter.rb lib/request_log_analyzer/filter/anonymize.rb lib/request_log_analyzer/filter/field.rb lib/request_log_analyzer/filter/timespan.rb lib/request_log_analyzer/line_definition.rb lib/request_log_analyzer/log_processor.rb lib/request_log_analyzer/mailer.rb lib/request_log_analyzer/output.rb lib/request_log_analyzer/output/fixed_width.rb lib/request_log_analyzer/output/html.rb lib/request_log_analyzer/request.rb lib/request_log_analyzer/source.rb lib/request_log_analyzer/source/log_parser.rb lib/request_log_analyzer/tracker.rb lib/request_log_analyzer/tracker/duration.rb lib/request_log_analyzer/tracker/frequency.rb lib/request_log_analyzer/tracker/hourly_spread.rb lib/request_log_analyzer/tracker/numeric_value.rb lib/request_log_analyzer/tracker/timespan.rb lib/request_log_analyzer/tracker/traffic.rb request-log-analyzer.gemspec spec/database.yml spec/fixtures/apache_combined.log spec/fixtures/apache_common.log spec/fixtures/decompression.log spec/fixtures/decompression.log.bz2 spec/fixtures/decompression.log.gz spec/fixtures/decompression.log.zip spec/fixtures/decompression.tar.gz spec/fixtures/decompression.tgz spec/fixtures/header_and_footer.log spec/fixtures/merb.log spec/fixtures/merb_prefixed.log spec/fixtures/multiple_files_1.log spec/fixtures/multiple_files_2.log spec/fixtures/mysql_slow_query.log spec/fixtures/oink_22.log spec/fixtures/oink_22_failure.log spec/fixtures/postgresql.log spec/fixtures/rails.db spec/fixtures/rails_1x.log spec/fixtures/rails_22.log spec/fixtures/rails_22_cached.log spec/fixtures/rails_3_partials.log spec/fixtures/rails_unordered.log spec/fixtures/s3_logs/2012-10-05-16-18-11-F9AAC5D1A55AEBAD spec/fixtures/s3_logs/2012-10-05-16-26-06-15314AF7F0651839 spec/fixtures/sinatra.log spec/fixtures/syslog_1x.log spec/fixtures/test_file_format.log spec/fixtures/test_language_combined.log spec/fixtures/test_order.log spec/integration/command_line_usage_spec.rb spec/integration/mailer_spec.rb spec/integration/munin_plugins_rails_spec.rb spec/integration/scout_spec.rb spec/lib/helpers.rb spec/lib/macros.rb spec/lib/matchers.rb spec/lib/mocks.rb spec/lib/testing_format.rb spec/spec_helper.rb spec/unit/aggregator/database_inserter_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/controller/controller_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/database/base_class_spec.rb spec/unit/database/connection_spec.rb spec/unit/database/database_spec.rb spec/unit/file_format/amazon_s3_format_spec.rb spec/unit/file_format/apache_format_spec.rb spec/unit/file_format/common_regular_expressions_spec.rb spec/unit/file_format/delayed_job21_format_spec.rb spec/unit/file_format/delayed_job2_format_spec.rb spec/unit/file_format/delayed_job3_format_spec.rb spec/unit/file_format/delayed_job_format_spec.rb spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/format_autodetection_spec.rb spec/unit/file_format/haproxy_format_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/mysql_format_spec.rb spec/unit/file_format/oink_format_spec.rb spec/unit/file_format/postgresql_format_spec.rb spec/unit/file_format/rack_format_spec.rb spec/unit/file_format/rails3_format_spec.rb spec/unit/file_format/rails_format_spec.rb spec/unit/file_format/w3c_format_spec.rb spec/unit/filter/anonymize_filter_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/filter/filter_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/mailer_spec.rb spec/unit/request_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/unit/tracker/numeric_value_tracker_spec.rb spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/traffic_tracker_spec.rb tasks/github-gem.rake tasks/request_log_analyzer.rake)
  s.test_files = %w(spec/integration/command_line_usage_spec.rb spec/integration/mailer_spec.rb spec/integration/munin_plugins_rails_spec.rb spec/integration/scout_spec.rb spec/unit/aggregator/database_inserter_spec.rb spec/unit/aggregator/summarizer_spec.rb spec/unit/controller/controller_spec.rb spec/unit/controller/log_processor_spec.rb spec/unit/database/base_class_spec.rb spec/unit/database/connection_spec.rb spec/unit/database/database_spec.rb spec/unit/file_format/amazon_s3_format_spec.rb spec/unit/file_format/apache_format_spec.rb spec/unit/file_format/common_regular_expressions_spec.rb spec/unit/file_format/delayed_job21_format_spec.rb spec/unit/file_format/delayed_job2_format_spec.rb spec/unit/file_format/delayed_job3_format_spec.rb spec/unit/file_format/delayed_job_format_spec.rb spec/unit/file_format/file_format_api_spec.rb spec/unit/file_format/format_autodetection_spec.rb spec/unit/file_format/haproxy_format_spec.rb spec/unit/file_format/line_definition_spec.rb spec/unit/file_format/merb_format_spec.rb spec/unit/file_format/mysql_format_spec.rb spec/unit/file_format/oink_format_spec.rb spec/unit/file_format/postgresql_format_spec.rb spec/unit/file_format/rack_format_spec.rb spec/unit/file_format/rails3_format_spec.rb spec/unit/file_format/rails_format_spec.rb spec/unit/file_format/w3c_format_spec.rb spec/unit/filter/anonymize_filter_spec.rb spec/unit/filter/field_filter_spec.rb spec/unit/filter/filter_spec.rb spec/unit/filter/timespan_filter_spec.rb spec/unit/mailer_spec.rb spec/unit/request_spec.rb spec/unit/source/log_parser_spec.rb spec/unit/tracker/duration_tracker_spec.rb spec/unit/tracker/frequency_tracker_spec.rb spec/unit/tracker/hourly_spread_spec.rb spec/unit/tracker/numeric_value_tracker_spec.rb spec/unit/tracker/timespan_tracker_spec.rb spec/unit/tracker/tracker_api_spec.rb spec/unit/tracker/traffic_tracker_spec.rb)
end
