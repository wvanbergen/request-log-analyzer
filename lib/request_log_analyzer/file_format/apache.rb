# 125.76.230.10 - - [02/Sep/2009:03:33:46 +0200] "GET /cart/install.txt HTTP/1.1" 404 214 "-" "Toata dragostea mea pentru diavola"
# 125.76.230.10 - - [02/Sep/2009:03:33:47 +0200] "GET /store/install.txt HTTP/1.1" 404 215 "-" "Toata dragostea mea pentru diavola"
# 10.0.1.1 - - [02/Sep/2009:05:08:33 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
# 10.0.1.1 - - [02/Sep/2009:06:41:51 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
# 69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"

module RequestLogAnalyzer::FileFormat
  
  class Apache < Base

    # A hash of predefined Apache log format strings
    LOG_FORMAT_DEFAULTS = {
      :common   => '%h %l %u %t "%r" %>s %b',
      :combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"'
    }

    # A hash that defines how the log format directives should be parsed.
    LOG_DIRECTIVES = {
      'h' => { :regexp => '([A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+)',  :captures => [{:name => :remote_host, :type => :string}] },
      'a' => { :regexp => '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})', :captures => [{:name => :remote_ip, :type => :string}] },
      'b' => { :regexp => '(\d+|-)', :captures => [{:name => :bytes_sent, :type => :integer}] },
      'c' => { :regexp => '(\+|\-|\X)', :captures => [{:name => :connection_status, :type => :integer}] },
      'l' => { :regexp => '([\w-]+)', :captures => [{:name => :remote_logname, :type => :nillable_string}] },
      'T' => { :regexp => '((?:\d+(?:\.\d+)?)|-)', :captures => [{:name => :duration, :type => :duration, :unit => :sec}] },
      't' => { :regexp => '\[([^\]]{26})\]', :captures => [{:name => :timestamp, :type => :timestamp}] },
      's' => { :regexp => '(\d{3})', :captures => [{:name => :http_status, :type => :integer}] },
      'u' => { :regexp => '(\w+|-)', :captures => [{:name => :user, :type => :nillable_string}] },
      'r' => { :regexp => '([A-Z]+) ([^\s]+) HTTP\/(\d+(?:\.\d+)*)', :captures => [{:name => :http_method, :type => :string},
                       {:name => :path, :type => :string}, {:name => :http_version, :type => :string}]},
      'i' => { 'Referer'    => { :regexp => '([^\s]+)', :captures => [{:name => :referer, :type => :nillable_string}] },
               'User-agent' => { :regexp => '(.*)',     :captures => [{:name => :user_agent, :type => :user_agent}] }
             }
    }

    # Creates the Apache log format language based on a Apache log format string.
    # It will set up the line definition and the report trackers according to the Apache access log format,
    # which should be passed as first argument. By default, is uses the 'combined' log format.
    def self.create(*args)
      access_line =  access_line_definition(args.first)
      self.new({ :access => access_line}, report_trackers(access_line))
    end

    # Creates the access log line definition based on the Apache log format string
    def self.access_line_definition(format_string)
      format_string ||= :combined
      format_string   = LOG_FORMAT_DEFAULTS[format_string.to_sym] || format_string

      line_regexp = ''
      captures    = []
      format_string.scan(/([^%]*)(?:%(?:\{([^\}]+)\})?>?([A-Za-z]))?/) do |literal, arg, variable|

        line_regexp << Regexp.quote(literal) # Make sure to parse the literal before the directive
        
        if variable
          # Check if we recognize the log directive
          directive = LOG_DIRECTIVES[variable]
          directive = directive[arg] if directive && arg

          if directive
            line_regexp << directive[:regexp]   # Parse the value of the directive
            captures    += directive[:captures] # Add the directive's information to the captures
          else
            line_regexp << '.*' # Just accept any input for this literal
          end
        end
      end
      
      # Return a new line definition object
      return RequestLogAnalyzer::LineDefinition.new(:access, :regexp => Regexp.new(line_regexp),
                                        :captures => captures, :header => true, :footer => true)
    end

    # Sets up the report trackers according to the access line definition.
    def self.report_trackers(line_definition)
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new

      analyze.timespan      if line_definition.captures?(:timestamp)
      analyze.hourly_spread if line_definition.captures?(:timestamp)

      analyze.frequency :category => :http_method, :amount => 20, :title => "HTTP methods"  if line_definition.captures?(:http_method)
      analyze.frequency :category => :http_status, :amount => 20, :title => "HTTP statuses" if line_definition.captures?(:http_status)
      analyze.frequency :category => :path, :amount => 20, :title => "Most popular URIs"    if line_definition.captures?(:path)

      analyze.frequency :category => :user_agent, :amount => 20, :title => "User agents"    if line_definition.captures?(:user_agent)
      analyze.frequency :category => :referer,    :amount => 20, :title => "Referers"       if line_definition.captures?(:referer)

      if line_definition.captures?(:path) && line_definition.captures?(:duration)
        analyze.duration :duration => :duration, :category => :path , :title => 'Request duration'
      end

      return analyze.trackers
    end

    # Define a custom Request class for the Apache file format to speed up timestamp handling.
    class Request < RequestLogAnalyzer::Request
      
      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }
      
      # Do not use DateTime.parse
      def convert_timestamp(value, definition)
        d = /^(\d{2})\/(\w{3})\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/.match(value).captures
        "#{d[2]}#{MONTHS[d[1]]}#{d[0]}#{d[3]}#{d[4]}#{d[5]}".to_i
      end
      
      def convert_user_agent(value, definition)
        value # TODO
      end
      
      def convert_nillable_string(value, definition)
        value == '-' ? nil : value
      end
    end
  end
end