module RequestLogAnalyzer::Tracker

  # Determines the average hourly spread of the parsed requests.
  # This spread is shown in a graph form.
  #
  # Accepts the following options:
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:output</tt> Direct output here (defaults to STDOUT)
  # * <tt>:unless</tt> Proc that has to return nil for a request to be passed to the tracker.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  #  Requests graph - average per day per hour
  #  --------------------------------------------------
  #    7:00 - 330 hits        : =======
  #    8:00 - 704 hits        : =================
  #    9:00 - 830 hits        : ====================
  #   10:00 - 822 hits        : ===================
  #   11:00 - 823 hits        : ===================
  #   12:00 - 729 hits        : =================
  #   13:00 - 614 hits        : ==============
  #   14:00 - 690 hits        : ================
  #   15:00 - 492 hits        : ===========
  #   16:00 - 355 hits        : ========
  #   17:00 - 213 hits        : =====
  #   18:00 - 107 hits        : ==
  #   ................
  class HourlySpread < Base

    attr_reader :hour_frequencies, :first, :last

    # Check if timestamp field is set in the options and prepare the result time graph.
    def prepare
      options[:field] ||= :timestamp
      @hour_frequencies = (0...24).map { 0 }
      @first, @last = 99999999999999, 0
    end

    # Check if the timestamp in the request and store it.
    # <tt>request</tt> The request.
    def update(request)
      timestamp = request.first(options[:field])
      @hour_frequencies[timestamp.to_s[8..9].to_i] +=1
      @first = timestamp if timestamp < @first
      @last  = timestamp if timestamp > @last
    end

    # Total amount of requests tracked
    def total_requests
      @hour_frequencies.inject(0) { |sum, value| sum + value }
    end


    # First timestamp encountered
    def first_timestamp
      DateTime.parse(@first.to_s, '%Y%m%d%H%M%S') rescue nil
    end

    # Last timestamp encountered
    def last_timestamp
      DateTime.parse(@last.to_s, '%Y%m%d%H%M%S') rescue nil
    end

    # Difference between last and first timestamp.
    def timespan
      last_timestamp - first_timestamp
    end
    
    # Generate an hourly spread report to the given output object.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)
      output.title(title)

      if total_requests == 0
        output << "None found.\n"
        return
      end

      days = [1, timespan].max
      output.table({}, {:align => :right}, {:type => :ratio, :width => :rest, :treshold => 0.15}) do |rows|
        @hour_frequencies.each_with_index do |requests, index|
          ratio            = requests.to_f / total_requests.to_f
          requests_per_day = (requests / days).ceil
          rows << ["#{index.to_s.rjust(3)}:00", "%d hits/day" % requests_per_day, ratio]
        end
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title] || "Request distribution per hour"
    end

    # Returns the found frequencies per hour as a hash for YAML exporting
    def to_yaml_object
      yaml_object = {}
      @hour_frequencies.each_with_index do |freq, hour|
        yaml_object["#{hour}:00 - #{hour+1}:00"] = freq
      end
      yaml_object
    end
  end
end
