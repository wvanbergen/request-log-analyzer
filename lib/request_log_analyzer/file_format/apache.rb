# 125.76.230.10 - - [02/Sep/2009:03:33:46 +0200] "GET /cart/install.txt HTTP/1.1" 404 214 "-" "Toata dragostea mea pentru diavola"
# 125.76.230.10 - - [02/Sep/2009:03:33:47 +0200] "GET /store/install.txt HTTP/1.1" 404 215 "-" "Toata dragostea mea pentru diavola"
# 10.0.1.1 - - [02/Sep/2009:05:08:33 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
# 10.0.1.1 - - [02/Sep/2009:06:41:51 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"
# 69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"

module RequestLogAnalyzer::FileFormat
  
  class Apache < Base

    # 125.76.230.10 - - [02/Sep/2009:03:33:46 +0200] "GET /cart/install.txt HTTP/1.1" 404 214 "-" "Toata dragostea mea pentru diavola"
    line_definition :access do |line|
      line.header = true
      line.footer = true
      line.regexp = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - - \[([^\]]{26})\] "([A-Z]+) ([^\s]+) HTTP\/(\d+(?:\.\d+)*)" (\d+) \d+ "-" "([^"]+)"/
      line.captures << { :name => :ip_address,   :type => :string } \
                    << { :name => :timestamp,    :type => :timestamp } \
                    << { :name => :method,       :type => :string } \
                    << { :name => :path,         :type => :string } \
                    << { :name => :http_version, :type => :string } \
                    << { :name => :status,       :type => :integer } \
                    << { :name => :user_agent,   :type => :string }
    end    

    
    report do |analyze|
      analyze.timespan :line_type => :access
      analyze.hourly_spread :line_type => :access
      analyze.frequency :category => :method, :amount => 20, :title => "HTTP methods frequency"
      analyze.frequency :category => :path,   :amount => 20, :title => "Most popular paths"
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
    end
  end
end