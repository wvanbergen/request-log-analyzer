module RequestLogAnalyzer::FileFormat

  class Haproxy < RequestLogAnalyzer::FileFormat::Base

    extend CommonRegularExpressions

    # Define line types
    line_definition :access do |line|
      line.header = true
      line.footer = true

      line.regexp = %r{
        (#{ip_address}):\d+\s # client_ip ':' client_port
        \[(#{timestamp('%d/%b/%Y:%H:%M:%S')})\.\d{3}\]\s # '[' accept_date ']'
        (\S+)\s # frontend_name
        (\S+)\/(\S+)\s # backend_name '/' server_name
        (\d+|-1)\/(\d+|-1)\/(\d+|-1)\/(\d+|-1)\/\+?(\d+)\s # Tq '/' Tw '/' Tc '/' Tr '/' Tt
        (\d+)\s # status_code
        \+?(\d+)\s # bytes_read
        (\S+)\s # captured_request_cookie
        (\S+)\s # captured_response_cookie
        (\w|-)(\w|-)(\w|-)(\w|-)\s # termination_state
        (\d+)\/(\d+)\/(\d+)\/(\d+)\/\+?(\d+)\s # actconn '/' feconn '/' beconn '/' srv_conn '/' retries
        (\d+)\/(\d+)\s # srv_queue '/' backend_queue
        (\S*)\s? # captured_request_headers
        (\S*)\s? # captured_response_headers
        "([^"]*)" # '"' http_request '"'
      }x

      line.capture(:client_ip).as(:string)
      line.capture(:timestamp).as(:timestamp)
      line.capture(:frontend_name).as(:string)
      line.capture(:backend_name).as(:string)
      line.capture(:server_name).as(:string)
      line.capture(:tq).as(:nillable_duration, :unit => :msec)
      line.capture(:tw).as(:nillable_duration, :unit => :msec)
      line.capture(:tc).as(:nillable_duration, :unit => :msec)
      line.capture(:tr).as(:nillable_duration, :unit => :msec)
      line.capture(:tt).as(:duration, :unit => :msec)
      line.capture(:status_code).as(:integer)
      line.capture(:bytes_read).as(:traffic, :unit => :byte)
      line.capture(:captured_request_cookie).as(:nillable_string)
      line.capture(:captured_response_cookie).as(:nillable_string)
      line.capture(:termination_event_code).as(:nillable_string)
      line.capture(:terminated_session_state).as(:nillable_string)
      line.capture(:clientside_persistence_cookie).as(:nillable_string)
      line.capture(:serverside_persistence_cookie).as(:nillable_string)
      line.capture(:actconn).as(:integer)
      line.capture(:feconn).as(:integer)
      line.capture(:beconn).as(:integer)
      line.capture(:srv_conn).as(:integer)
      line.capture(:retries).as(:integer)
      line.capture(:srv_queue).as(:integer)
      line.capture(:backend_queue).as(:integer)
      line.capture(:captured_request_headers).as(:nillable_string)
      line.capture(:captured_response_headers).as(:nillable_string)
      line.capture(:http_request).as(:nillable_string)
    end

    # Define the summary report
    report do |analyze|
      analyze.hourly_spread :field => :timestamp

      analyze.frequency :client_ip,
        :title => "Hits per IP"

      analyze.frequency :frontend_name,
        :title => "Hits per frontend service"

      analyze.frequency :backend_name,
        :title => "Hits per backend service"

      analyze.frequency :server_name,
        :title => "Hits per backend server"

      analyze.frequency :status_code,
        :title => "HTTP response code frequency"

      analyze.frequency :http_request,
        :title => "Most popular requests"

      analyze.frequency :http_request,
        :title => "Most frequent HTTP 40x errors",
        :category => lambda { |r| "#{r[:http_request]}"},
        :if => lambda { |r| r[:status_code] >= 400 and r[:status_code] <= 417 }

      analyze.frequency :http_request,
        :title => "Most frequent HTTP 50x errors",
        :category => lambda { |r| "#{r[:http_request]}"},
        :if => lambda { |r| r[:status_code] >= 500 and r[:status_code] <= 505 }

      analyze.traffic :bytes_read,
        :title => "Traffic per frontend service",
        :category => lambda { |r| "#{r[:frontend_name]}"}

      analyze.traffic :bytes_read,
        :title => "Traffic per backend service",
        :category => lambda { |r| "#{r[:backend_name]}"}

      analyze.traffic :bytes_read,
        :title => "Traffic per backend server",
        :category => lambda { |r| "#{r[:server_name]}"}

      analyze.duration :tr,
        :title => "Time waiting for backend response",
        :category => lambda { |r| "#{r[:http_request]}"}

      analyze.duration :tt,
        :title => "Total time spent on request",
        :category => lambda { |r| "#{r[:http_request]}"}
    end

    # Define a custom Request class for the HAProxy file format to speed up
    # timestamp handling. Shamelessly copied from apache.rb
    class Request < RequestLogAnalyzer::Request

      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }

      # Do not use DateTime.parse, but parse the timestamp ourselves to return
      # a integer to speed up parsing.
      def convert_timestamp(value, definition)
        "#{value[7,4]}#{MONTHS[value[3,3]]}#{value[0,2]}#{value[12,2]}#{value[15,2]}#{value[18,2]}".to_i
      end

      # Make sure that the strings '-' or '{}' or '' are parsed as a nil value.
      def convert_nillable_string(value, definition)
        value =~ /-|\{\}|^$/ ? nil : value
      end

      # Make sure that -1 is parsed as a nil value.
      def convert_nillable_duration(value, definition)
        value == '-1' ? nil : convert_duration(value, definition)
      end

    end
  end
end
