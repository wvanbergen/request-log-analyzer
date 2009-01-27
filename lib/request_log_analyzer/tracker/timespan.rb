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
  class Timespan < Base

    attr_reader :first, :last, :request_time_graph

    def prepare
      options[:field] ||= :timestamp
    end
            
    def update(request)
      timestamp = request[options[:field]]

      @first = timestamp if @first.nil? || timestamp < @first
      @last  = timestamp if @last.nil?  || timestamp > @last
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
      output.title(options[:title]) if options[:title]
    
      if @last && @first
        output.with_style(:cell_separator => false) do         
          output.table({:width => 20}, {}) do |rows|
            rows << ['First request:', first_timestamp.strftime('%Y-%m-%d %H:%M:%I')]
            rows << ['Last request:', last_timestamp.strftime('%Y-%m-%d %H:%M:%I')]
            rows << ['Total time analyzed:', "#{timespan.ceil} days"]                    
          end
        end
      end
    
    end
  end
end
