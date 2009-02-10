module RequestLogAnalyzer::Tracker
  
  # Determines the average hourly spread of the parsed requests.
  # This spread is shown in a graph form.
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  #  Requests graph - average per day per hour
  #  --------------------------------------------------
  #    7:00 - 330 hits        : ░░░░░░░
  #    8:00 - 704 hits        : ░░░░░░░░░░░░░░░░░
  #    9:00 - 830 hits        : ░░░░░░░░░░░░░░░░░░░░
  #   10:00 - 822 hits        : ░░░░░░░░░░░░░░░░░░░
  #   11:00 - 823 hits        : ░░░░░░░░░░░░░░░░░░░
  #   12:00 - 729 hits        : ░░░░░░░░░░░░░░░░░
  #   13:00 - 614 hits        : ░░░░░░░░░░░░░░
  #   14:00 - 690 hits        : ░░░░░░░░░░░░░░░░
  #   15:00 - 492 hits        : ░░░░░░░░░░░
  #   16:00 - 355 hits        : ░░░░░░░░
  #   17:00 - 213 hits        : ░░░░░
  #   18:00 - 107 hits        : ░░
  #   ................
  class HourlySpread < Base

    attr_reader :first, :last, :request_time_graph

    def prepare
      options[:field] ||= :timestamp
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    end
            
    def update(request)
      request = request.attributes
      timestamp = request[options[:field]]

      @request_time_graph[timestamp.to_s[8..9].to_i] +=1
      @first = timestamp if @first.nil? || timestamp < @first
      @last  = timestamp if @last.nil?  || timestamp > @last
    end

    def total_requests
      @request_time_graph.inject(0) { |sum, value| sum + value }
    end
    
    def first_timestamp
      DateTime.parse(@first.to_s, '%Y%m%d%H%M%S') rescue nil
    end
    
    def last_timestamp
      DateTime.parse(@last.to_s, '%Y%m%d%H%M%S') rescue nil
    end
    
    def timespan
      last_timestamp - first_timestamp
    end

    def report(output)
      output.title("Requests graph - average per day per hour")
    
      if total_requests == 0
        output << "None found.\n"
        return
      end

      days = [1, timespan].max
      output.table({}, {:align => :right}, {:type => :ratio, :width => :rest, :treshold => 0.15}) do |rows|
        @request_time_graph.each_with_index do |requests, index|
          ratio = requests.to_f / total_requests.to_f
          requests_per_day = (requests / days).ceil
          rows << ["#{index.to_s.rjust(3)}:00", "%d hits" % requests_per_day, ratio]
        end
      end
    end
  end
end
