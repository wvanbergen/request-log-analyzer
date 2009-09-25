module RequestLogAnalyzer::Tracker

  # Determines the datetime of the first request and the last request
  # Also determines the amount of days inbetween these.
  #
  # Accepts the following options:
  # * <tt>:field</tt> The timestamp field that is looked at. Defaults to :timestamp.
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:title</tt> Title do be displayed above the report.
  # * <tt>:unless</tt> Proc that has to return nil for a request to be passed to the tracker.
  #
  # Expects the following items in the update request hash
  # * <tt>:timestamp</tt> in YYYYMMDDHHMMSS format.
  #
  # Example output:
  #  First request:        2008-07-13 06:25:06
  #  Last request:         2008-07-20 06:18:06
  #  Total time analyzed:  7 days
  class Timespan < Base

    attr_reader :first, :last

    # Check if timestamp field is set in the options.
    def prepare
      options[:field] ||= :timestamp
      @first, @last = 99999999999999, 0
    end

    # Check if the timestamp in the request and store it.
    # <tt>request</tt> The request.
    def update(request)
      timestamp = request[options[:field]]
      @first = timestamp if timestamp < @first
      @last  = timestamp if timestamp > @last
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
      output.title(options[:title]) if options[:title]

      if @last > 0 && @first < 99999999999999
        output.with_style(:cell_separator => false) do
          output.table({:width => 20}, {}) do |rows|
            rows << ['First request:', first_timestamp.strftime('%Y-%m-%d %H:%M:%I')]
            rows << ['Last request:',  last_timestamp.strftime('%Y-%m-%d %H:%M:%I')]
            rows << ['Total time analyzed:', "#{timespan.ceil} days"]
          end
        end
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title] || 'Request timespan'
    end

    # A hash that can be exported to YAML with the first and last timestamp encountered.
    def to_yaml_object
      { :first => first_timestamp, :last  =>last_timestamp }
    end

  end
end
