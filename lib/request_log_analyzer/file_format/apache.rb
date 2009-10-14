module RequestLogAnalyzer::FileFormat

  # The Apache file format is able to log Apache access.log files.
  #
  # The access.log can be configured in Apache to have many different formats. In theory, this
  # FileFormat can handle any format, but it must be aware of the log formatting that is used
  # by sending the formatting string as parameter to the create method, e.g.:
  #
  #     RequestLogAnalyzer::FileFormat::Apache.create('%h %l %u %t "%r" %>s %b')
  #
  # It also supports the predefined Apache log formats "common" and "combined". The line
  # definition and the report definition will be constructed using this file format string.
  # From the command line, you can provide the format string using the <tt>--apache-format</tt>
  # command line option.
  class Apache < Base

    # A hash of predefined Apache log formats
    LOG_FORMAT_DEFAULTS = {
      :common   => '%h %l %u %t "%r" %>s %b',
      :combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"',
      :rack     => '%h %l %u %t "%r" %>s %b %T',
      :referer  => '%{Referer}i -> %U',
      :agent    => '%{User-agent}i'
    }

    # A hash that defines how the log format directives should be parsed.
    LOG_DIRECTIVES = {
      '%' => { :regexp => '%', :captures => [] },
      'h' => { :regexp => '([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)',  :captures => [{:name => :remote_host, :type => :string}] },
      'a' => { :regexp => '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', :captures => [{:name => :remote_ip, :type => :string}] },
      'b' => { :regexp => '(\d+|-)', :captures => [{:name => :bytes_sent, :type => :traffic}] },
      'c' => { :regexp => '(\+|\-|\X)', :captures => [{:name => :connection_status, :type => :integer}] },
      'D' => { :regexp => '(\d+|-)', :captures => [{:name => :duration, :type => :duration, :unit => :musec}] },
      'l' => { :regexp => '([\w-]+)', :captures => [{:name => :remote_logname, :type => :nillable_string}] },
      'T' => { :regexp => '((?:\d+(?:\.\d+))|-)', :captures => [{:name => :duration, :type => :duration, :unit => :sec}] },
      't' => { :regexp => '\[(\d{2}\/[A-Za-z]{3}\/\d{4}.\d{2}:\d{2}:\d{2})(?: .\d{4})?\]', :captures => [{:name => :timestamp, :type => :timestamp}] },
      's' => { :regexp => '(\d{3})', :captures => [{:name => :http_status, :type => :integer}] },
      'u' => { :regexp => '(\w+|-)', :captures => [{:name => :user, :type => :nillable_string}] },
      'U' => { :regexp => '(\/\S*)', :captures => [{:name => :path, :type => :string}] },
      'r' => { :regexp => '([A-Z]+) (\S+) HTTP\/(\d+(?:\.\d+)*)', :captures => [{:name => :http_method, :type => :string},
                       {:name => :path, :type => :path}, {:name => :http_version, :type => :string}]},
      'i' => { 'Referer'    => { :regexp => '(\S+)', :captures => [{:name => :referer, :type => :nillable_string}] },
               'User-agent' => { :regexp => '(.*)',  :captures => [{:name => :user_agent, :type => :user_agent}] }
             }
    }

    # Creates the Apache log format language based on a Apache log format string.
    # It will set up the line definition and the report trackers according to the Apache access log format,
    # which should be passed as first argument. By default, is uses the 'combined' log format.
    def self.create(*args)
      access_line = access_line_definition(args.first)
      trackers = report_trackers(access_line) + report_definer.trackers
      self.new(line_definer.line_definitions.merge(:access => access_line), trackers)
    end

    # Creates the access log line definition based on the Apache log format string
    def self.access_line_definition(format_string)
      format_string ||= :common
      format_string   = LOG_FORMAT_DEFAULTS[format_string.to_sym] || format_string

      line_regexp = ''
      captures    = []
      format_string.scan(/([^%]*)(?:%(?:\{([^\}]+)\})?>?([A-Za-z%]))?/) do |literal, arg, variable|

        line_regexp << Regexp.quote(literal) # Make sure to parse the literal before the directive

        if variable
          # Check if we recognize the log directive
          directive = LOG_DIRECTIVES[variable]
          directive = directive[arg] if directive && arg

          if directive
            line_regexp << directive[:regexp]   # Parse the value of the directive
            captures    += directive[:captures] # Add the directive's information to the captures
          else
            puts "%#{directive} log directiven not yet supported, field is ignored."
            line_regexp << '.*' # Just accept any input for this literal
          end
        end
      end

      # Return a new line definition object
      return RequestLogAnalyzer::LineDefinition.new(:access, :regexp => Regexp.new(line_regexp),
                                        :captures => captures, :header => true, :footer => true)
    end

    # Sets up the report trackers according to the fields captured by the access line definition.
    def self.report_trackers(line_definition)
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new

      analyze.timespan      if line_definition.captures?(:timestamp)
      analyze.hourly_spread if line_definition.captures?(:timestamp)

      analyze.frequency :category => :http_method, :title => "HTTP methods"  if line_definition.captures?(:http_method)
      analyze.frequency :category => :http_status, :title => "HTTP statuses" if line_definition.captures?(:http_status)
      analyze.frequency :category => lambda { |r| r.category }, :title => "Most popular URIs"    if line_definition.captures?(:path)

      analyze.frequency :category => :user_agent, :title => "User agents"    if line_definition.captures?(:user_agent)
      analyze.frequency :category => :referer,    :title => "Referers"       if line_definition.captures?(:referer)

      analyze.duration :duration => :duration,  :category => lambda { |r| r.category }, :title => 'Request duration' if line_definition.captures?(:duration)
      analyze.traffic  :traffic => :bytes_sent, :category => lambda { |r| r.category }, :title => 'Traffic'          if line_definition.captures?(:bytes_sent)

      return analyze.trackers
    end

    # Define a custom Request class for the Apache file format to speed up timestamp handling.
    class Request < RequestLogAnalyzer::Request

      def category
        first(:path)
      end

      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }

      # Do not use DateTime.parse, but parse the timestamp ourselves to return a integer
      # to speed up parsing.
      def convert_timestamp(value, definition)
        "#{value[7,4]}#{MONTHS[value[3,3]]}#{value[0,2]}#{value[12,2]}#{value[15,2]}#{value[18,2]}".to_i
      end

      # This function can be overridden to rewrite the path for better categorization in the
      # reports.
      def convert_path(value, definition)
        value
      end

      # This function can be overridden to simplify the user agent string for better
      # categorization in the reports
      def convert_user_agent(value, definition)
        value # TODO
      end

      # Make sure that the string '-' is parsed as a nil value.
      def convert_nillable_string(value, definition)
        value == '-' ? nil : value
      end
    end
  end
end