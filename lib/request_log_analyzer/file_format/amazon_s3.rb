module RequestLogAnalyzer::FileFormat

  # FileFormat for Amazon S3 access logs. 
  #
  # Access logs are disabled by default on Amazon S3. To enable logging, see
  # http://docs.amazonwebservices.com/AmazonS3/latest/index.html?ServerLogs.html
  class AmazonS3 < Base
    
    line_definition :access do |line|
      line.header = true
      line.footer = true
      line.regexp = /^([^\ ]+) ([^\ ]+) \[([^\]]{26})\] (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) ([^\ ]+) ([^\ ]+) (\w+(?:\.\w+)*) ([^\ ]+) "([^"]+)" (\d+) ([^\ ]+) (\d+) (\d+) (\d+) (\d+) "([^"]+)" "([^"]+)"/
      line.captures << { :name => :bucket_owner,    :type => :string } << 
                       { :name => :bucket,          :type => :string } << 
                       { :name => :timestamp,       :type => :timestamp } <<
                       { :name => :remote_ip,       :type => :string } <<
                       { :name => :requester,       :type => :string } << 
                       { :name => :request_id,      :type => :string } <<
                       { :name => :operation,       :type => :string } <<
                       { :name => :key,             :type => :nillable_string } <<
                       { :name => :request_uri,     :type => :string } <<
                       { :name => :http_status,     :type => :integer } <<
                       { :name => :error_code,      :type => :nillable_string } <<
                       { :name => :bytes_sent,      :type => :integer } <<
                       { :name => :object_size,     :type => :integer } <<
                       { :name => :total_time,      :type => :duration, :unit => :msec } <<
                       { :name => :turnaround_time, :type => :duration, :unit => :msec } <<
                       { :name => :referer,         :type => :referer } <<
                       { :name => :user_agent,      :type => :user_agent }
    end
    
    class Request < RequestLogAnalyzer::Request
      
      MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
                'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }
      
      # Do not use DateTime.parse, but parse the timestamp ourselves to return a integer
      # to speed up parsing.
      def convert_timestamp(value, definition)
        d = /^(\d{2})\/(\w{3})\/(\d{4}):(\d{2}):(\d{2}):(\d{2})/.match(value).captures
        "#{d[2]}#{MONTHS[d[1]]}#{d[0]}#{d[3]}#{d[4]}#{d[5]}".to_i
      end
      
      # Make sure that the string '-' is parsed as a nil value.
      def convert_nillable_string(value, definition)
        value == '-' ? nil : value
      end
      
      # Can be implemented in subclasses for improved categorizations
      def convert_referer(value, definition)
        value == '-' ? nil : value
      end
      
      # Can be implemented in subclasses for improved categorizations
      def convert_user_agent(value, definition)
        value == '-' ? nil : value
      end
    end
    
  end
end
