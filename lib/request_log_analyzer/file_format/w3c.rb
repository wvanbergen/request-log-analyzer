module RequestLogAnalyzer::FileFormat

  # FileFormat for W3C access logs.
  class W3c < Base
    
    extend CommonRegularExpressions

    line_definition :access do |line|
      line.header = true
      line.footer = true
      line.regexp = /^(#{timestamp('%Y-%m-%d %H:%M:%S')}) (#{ip_address}) (.*) (#{ip_address}) (\d+) (\w+) (\S+) \- (\d+) (\d+) (\d+) (\d+) (.*) (\S+)/
      
      line.capture(:timestamp).as(:timestamp)
      line.capture(:remote_ip)
      line.capture(:username).as(:nillable_string)
      line.capture(:local_ip)
      line.capture(:port).as(:integer)
      line.capture(:method)
      line.capture(:path).as(:path)
      line.capture(:http_status).as(:integer)
      line.capture(:bytes_sent).as(:traffic, :unit => :byte)
      line.capture(:bytes_received).as(:traffic, :unit => :byte)
      line.capture(:duration).as(:duration, :unit => :msec)
      line.capture(:user_agent)
      line.capture(:referer)
    end

    report do |analyze|
      analyze.timespan
      analyze.hourly_spread

      analyze.frequency :category => :http_method, :title => "HTTP methods"
      analyze.frequency :category => :http_status, :title => "HTTP statuses"
      
      analyze.frequency :category => :path, :title => "Most popular URIs"

      analyze.frequency :category => :user_agent, :title => "User agents"
      analyze.frequency :category => :referer,    :title => "Referers"

      analyze.duration :duration => :duration,  :category => :path, :title => 'Request duration'
      analyze.traffic  :traffic => :bytes_sent, :category => :path, :title => 'Traffic out'
      analyze.traffic  :traffic => :bytes_received, :category => :path, :title => 'Traffic in'
    end
    
    class Request < RequestLogAnalyzer::Request
      # Do not use DateTime.parse, but parse the timestamp ourselves to return a integer
      # to speed up parsing.
      def convert_timestamp(value, definition)
        "#{value[0,4]}#{value[5,2]}#{value[8,2]}#{value[11,2]}#{value[14,2]}#{value[17,2]}".to_i
      end
    end
  end
end
