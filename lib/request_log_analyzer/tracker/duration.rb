module RequestLogAnalyzer::Tracker

  # Analyze the duration of a specific attribute
  #
  # === Options
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:duration</tt> The field containing the duration in the request hash.
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:title</tt> Title do be displayed above the report
  # * <tt>:unless</tt> Handle request if this proc is false for the handled request.
  #
  # The items in the update request hash are set during the creation of the Duration tracker.
  #
  # Example output:
  #  Request duration - top 20 by cumulative time   |    Hits |      Sum. |      Avg.
  #  ---------------------------------------------------------------------------------
  #  EmployeeController#show.html [GET]             |    4742 |  4922.56s |     1.04s
  #  EmployeeController#update.html [POST]          |    4647 |  2731.23s |     0.59s
  #  EmployeeController#index.html [GET]            |    5802 |  1477.32s |     0.25s
  #  .............
  class Duration < NumericValue

    # Check if duration and catagory option have been received,
    def prepare
      options[:value] = options[:duration] if options[:duration]
      super
      
      @number_of_buckets = options[:number_of_buckets] || 1000
      @min_bucket_value  = options[:min_bucket_value] ? options[:min_bucket_value].to_f : 0.0001
      @max_bucket_value  = options[:max_bucket_value] ? options[:max_bucket_value].to_f : 1000

      # precalculate the bucket size
      @bucket_size = (Math.log(@max_bucket_value) - Math.log(@min_bucket_value)) / @number_of_buckets.to_f
    end

    # Display a duration
    def display_value(time)
      case time
      when nil       then '-'
      when 0...60    then "%0.02fs" % time
      when 60...3600 then "%dm%02ds" % [time / 60, (time % 60).round]
      else                "%dh%02dm%02ds" % [time / 3600, (time % 3600) / 60, (time % 60).round]
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Request duration'
    end
  end
end
