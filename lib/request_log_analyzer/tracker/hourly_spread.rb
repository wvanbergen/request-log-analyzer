module RequestLogAnalyzer::Tracker

  # Determines the average hourly spread of the parsed requests.
  # This spread is shown in a graph form.
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return true for a request to be passed to the tracker.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  # Requests graph - average per day per hour
  #  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #   7:00 - 330 hits        : ░░░░░░░
  #   8:00 - 704 hits        : ░░░░░░░░░░░░░░░░░
  #   9:00 - 830 hits        : ░░░░░░░░░░░░░░░░░░░░
  #  10:00 - 822 hits        : ░░░░░░░░░░░░░░░░░░░
  #  11:00 - 823 hits        : ░░░░░░░░░░░░░░░░░░░
  #  12:00 - 729 hits        : ░░░░░░░░░░░░░░░░░
  #  13:00 - 614 hits        : ░░░░░░░░░░░░░░
  #  14:00 - 690 hits        : ░░░░░░░░░░░░░░░░
  #  15:00 - 492 hits        : ░░░░░░░░░░░
  #  16:00 - 355 hits        : ░░░░░░░░
  #  17:00 - 213 hits        : ░░░░░
  #  18:00 - 107 hits        : ░░
  #  ................
  class HourlySpread < RequestLogAnalyzer::Tracker::Base

    attr_reader :first, :last, :request_time_graph
  
    def prepare
      options[:field] ||= :timestamp
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
