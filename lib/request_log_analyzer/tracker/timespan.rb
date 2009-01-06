module RequestLogAnalyzer::Tracker

  # Determines the datetime of the first request and the last request
  # Also determines the amount of days inbetween these.
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:field</tt> The timestamp field that is looked at. Defaults to :timestamp.
  # * <tt>:title</tt> Title do be displayed above the report.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  #  First request:        2008-07-13 06:25:06
  #  Last request:         2008-07-20 06:18:06
  #  Total time analyzed:  7 days
  class Timespan < RequestLogAnalyzer::Tracker::Base

    attr_reader :first, :last, :request_time_graph
  
    def prepare
      options[:field] ||= :timestamp
    end
              
    def update(request)
      timestamp = request[options[:field]]

      @first = timestamp if @first.nil? || timestamp < @first
      @last  = timestamp if @last.nil?  || timestamp > @last
    end
  
    def report(report_width = 80, color = false)
      if options[:title]
        @output << "\n#{options[:title]}\n"
        @output << green('━' * options[:title].length, color) + "\n"
      end
      
      first_date  = DateTime.parse(@first.to_s, '%Y%m%d%H%M%S')
      last_date   = DateTime.parse(@last.to_s, '%Y%m%d%H%M%S')
      days        = (@last && @first) ? (last_date - first_date).ceil : 1

      @output << "First request:        #{first_date.strftime('%Y-%m-%d %H:%M:%I')}\n"
      @output << "Last request:         #{last_date.strftime('%Y-%m-%d %H:%M:%I')}\n"
      @output << "Total time analyzed:  #{days} days\n"
      @output << "\n"
    end
  end
end