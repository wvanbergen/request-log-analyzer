module RequestLogAnalyzer::FileFormat

  # FileFormat for Sinatra access logs.
  class Sinatra < Base

    line_definition :comment do |line|
      line.header = false
      line.footer = false
      line.regexp = /\=\=\ Sinatra\ (.*)/
      line.captures << { :name => :sinatra_comment, :type => :string }
    end

    line_definition :request do |line|
      line.header = true
      line.footer = true
      line.regexp = /^(\d+\.\d+\.\d+\.\d+)\ \-\ \-\ \[(\d+\/\w+\/\d+\ \d+:\d\d:\d\d)\]\ \"(\w+)\ (.*)\ (.*)\"\ (\d+)\ (\d+)\ (.*)/
      line.captures << { :name => :ip,              :type => :string } <<
                       { :name => :timestamp,       :type => :timestamp } <<
                       { :name => :method,          :type => :string } <<
                       { :name => :request_uri,     :type => :string } <<
                       { :name => :http_version,    :type => :string } <<
                       { :name => :http_status,     :type => :integer } <<
                       { :name => :bytes_sent,      :type => :traffic,  :unit => :byte } <<
                       { :name => :total_time,      :type => :duration, :unit => :msec }
    end

    report do |analyze|
      analyze.timespan
      analyze.hourly_spread

      REQUEST_CATEGORIZER = Proc.new do |request|
        category = "#{request[:request_uri]}"
        category
      end

      analyze.frequency :category => REQUEST_CATEGORIZER, :title => "Most popular items"
      analyze.duration :duration => :total_time, :category => REQUEST_CATEGORIZER, :title => "Request duration"
      analyze.traffic  :traffic => :bytes_sent,  :category => REQUEST_CATEGORIZER, :title => "Traffic"
      analyze.frequency :category => :http_status, :title => 'HTTP status codes'
    end

    class Request < RequestLogAnalyzer::Request

      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }

      # Do not use DateTime.parse, but parse the timestamp ourselves to return a integer
      # to speed up parsing.
      def convert_timestamp(value, definition)
        "#{value[7,4]}#{MONTHS[value[3,3]]}#{value[0,2]}#{value[12,2]}#{value[15,2]}#{value[18,2]}".to_i
      end
    end

  end
end
