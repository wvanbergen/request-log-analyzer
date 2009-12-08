module RequestLogAnalyzer::FileFormat

  # The Merb file format parses the request header with the timestamp, the params line
  # with the most important request information and the durations line which contains
  # the different request durations that can be used for analysis.
  class Merb < Base

    extend CommonRegularExpressions

    # ~ Started request handling: Fri Aug 29 11:10:23 +0200 2008
    line_definition :started do |line|
      line.header = true
      line.teaser = /Started request handling\:/
      line.regexp = /Started request handling\:\ (#{timestamp('%a %b %d %H:%M:%S %z %Y')})/
      line.captures << { :name => :timestamp, :type => :timestamp }
    end

    # ~ Params: {"action"=>"create", "controller"=>"session"}
    # ~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"destroy"}
    line_definition :params do |line|
      line.teaser = /Params\:\ /
      line.regexp = /Params\:\ (\{.+\})/
      line.captures << { :name => :params, :type => :eval, :provides => {
            :namespace => :string, :controller => :string, :action => :string, :format => :string, :method => :string } }
    end

    # ~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}
    line_definition :completed do |line|
      line.footer = true
      # line.teaser = Regexp.new(Regexp.quote('~ {:'))
      line.regexp = /(\{.*\:dispatch_time\s*=>\s*\d+\.\d+.*\})/
      line.captures << { :name => :times_hash, :type => :eval, :provides => {
            :dispatch_time => :duration, :after_filters_time => :duration,
            :before_filters_time => :duration, :action_time => :duration } }
    end

    REQUEST_CATEGORIZER = Proc.new do |request|
      category = "#{request[:controller]}##{request[:action]}"
      category = "#{request[:namespace]}::#{category}" if request[:namespace]
      category = "#{category}.#{request[:format]}"     if request[:format]
      category
    end

    report do |analyze|

      analyze.timespan
      analyze.hourly_spread

      analyze.frequency :category => REQUEST_CATEGORIZER, :title => "Top 20 by hits"
      analyze.duration :dispatch_time, :category => REQUEST_CATEGORIZER, :title => 'Request dispatch duration'

      # analyze.duration :action_time, :category => REQUEST_CATEGORIZER, :title => 'Request action duration'
      # analyze.duration :after_filters_time, :category => REQUEST_CATEGORIZER, :title => 'Request after_filter duration'
      # analyze.duration :before_filters_time, :category => REQUEST_CATEGORIZER, :title => 'Request before_filter duration'
    end

    class Request < RequestLogAnalyzer::Request

      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }

      # Speed up timestamp conversion
      def convert_timestamp(value, definition)
        "#{value[26,4]}#{MONTHS[value[4,3]]}#{value[8,2]}#{value[11,2]}#{value[14,2]}#{value[17,2]}".to_i
      end
    end
  end

end