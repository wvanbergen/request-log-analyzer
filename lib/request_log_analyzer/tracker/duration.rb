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
  class Duration < Base

    include RequestLogAnalyzer::Tracker::StatisticsTracking

    attr_reader :categories

    # Check if duration and catagory option have been received,
    def prepare
      raise "No duration field set up for category tracker #{self.inspect}" unless options[:duration]
      raise "No categorizer set up for duration tracker #{self.inspect}"    unless options[:category]

      unless options[:multiple]
        @categorizer  = create_lambda(options[:category])
        @durationizer = create_lambda(options[:duration])
      end
      
      @categories   = {}
    end

    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      if options[:multiple]
        found_categories = request.every(options[:category])
        found_durations  = request.every(options[:duration])
        raise "Capture mismatch for multiple values in a request" unless found_categories.length == found_durations.length
        found_categories.each_with_index { |cat, index| update_statistics(cat, found_durations[index]) }
      else
        category = @categorizer.call(request)
        duration = @durationizer.call(request)
        update_statistics(category, duration) if duration.kind_of?(Numeric) && category
      end
    end

    # Block function to build a result table using a provided sorting function.
    # <tt>output</tt> The output object.
    # <tt>amount</tt> The number of rows in the report table (default 10).
    # === Options
    #  * </tt>:title</tt> The title of the table
    #  * </tt>:sort</tt> The key to sort on (:hits, :cumulative, :average, :min or :max)
    def report_table(output, sort, options = {}, &block)
      output.puts
      top_categories = output.slice_results(sorted_by(sort))
      output.with_style(:top_line => true) do
        output.table(*statistics_header(:title => options[:title], :highlight => sort)) do |rows|
          top_categories.each { |(cat, info)| rows << statistics_row(cat) }
        end
      end
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

    # Generate a request duration report to the given output object
    # By default colulative and average duration are generated.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)
      sortings = output.options[:sort] || [:sum, :mean]
      sortings.each do |sorting|
        report_table(output, sorting, :title => "#{title} - by #{sorting}")
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Request duration'
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories
    end
  end
end
