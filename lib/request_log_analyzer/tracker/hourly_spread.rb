module RequestLogAnalyzer::Tracker

  class HourlySpread < RequestLogAnalyzer::Tracker::Base

    attr_reader :first, :last, :request_time_graph
  
    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:field]
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    end
              
    def update(request)
      timestamp = request[options[:field]]

      @request_time_graph[timestamp.to_s[8..9].to_i] +=1
      @first = timestamp if @first.nil? || timestamp < @first
      @last  = timestamp if @last.nil?  || timestamp > @last
    end
  
    def report(report_width = 80, color = false)
      puts ""
      puts "Requests graph - average per day per hour"
      puts green("━" * report_width, color)

      first_date    = DateTime.parse(@first.to_s, '%Y%m%d%H%M%S')
      last_date     = DateTime.parse(@last.to_s, '%Y%m%d%H%M%S')
      days          = (@last && @first) ? (last_date - first_date).ceil : 1
      deviation     = @request_time_graph.max / 20
      deviation     = 1 if deviation == 0
      color_cutoff  = 15
      
      @request_time_graph.each_with_index do |requests, index|
        display_chars = requests / deviation
        request_today = requests / days
      
        if display_chars >= color_cutoff
          display_chars_string = green(('░' * color_cutoff), color) + red(('░' * (display_chars - color_cutoff)), color)
        else
          display_chars_string = green(('░' * display_chars), color)
        end
      
        puts "#{index.to_s.rjust(3)}:00 - #{(request_today.to_s + ' hits').ljust(15)} : #{display_chars_string}"
      end
      puts ""

    end
  end
end
