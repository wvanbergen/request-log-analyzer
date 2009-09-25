module RequestLogAnalyzer::Tracker

  # Analyze the average and total traffic of requests
  #
  # === Options
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:traffic</tt> The field containing the duration in the request hash.
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:title</tt> Title do be displayed above the report
  # * <tt>:unless</tt> Handle request if this proc is false for the handled request.
  class Traffic < Base

    attr_reader :categories

    include RequestLogAnalyzer::Tracker::StatisticsTracking

    # Check if duration and catagory option have been received,
    def prepare
      raise "No traffic field set up for category tracker #{self.inspect}" unless options[:traffic]
      raise "No categorizer set up for duration tracker #{self.inspect}"   unless options[:category]

      @categorizer = create_lambda(options[:category])
      @trafficizer = create_lambda(options[:traffic])
      @categories  = {}
    end


    # Get the duration information from the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      category = @categorizer.call(request)
      traffic  = @trafficizer.call(request)
      update_statistics(category, traffic) if traffic.kind_of?(Numeric) && !category.nil?
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
        output.table(*statistics_header(:title => options[:title],:highlight => sort)) do |rows|
          top_categories.each { |(cat, info)| rows.push(statistics_row(cat)) }
        end
      end
      output.puts
    end

    # Formats the traffic number using x B/kB/MB/GB etc notation
    def display_value(bytes)
      return "-"   if bytes.nil?
      return "0 B" if bytes.zero?
      case Math.log10(bytes).floor
      when  1...4  then '%d B'  % bytes
      when  4...7  then '%d kB' % (bytes / 1000)
      when  7...10 then '%d MB' % (bytes / 1000_000)
      when 10...13 then '%d GB' % (bytes / 1000_000_000)
      else              '%d TB' % (bytes / 1000_000_000_000)
      end
    end

    # Generate a request duration report to the given output object
    # By default colulative and average duration are generated.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)

      sortings = output.options[:sort] || [:sum, :mean]

      sortings.each do |report|
        case report
        when :mean
          report_table(output, :mean,   :title => "#{title} - sorted by mean")
        when :stddev
          report_table(output, :stddev, :title => "#{title} - sorted by standard deviation")
        when :sum
          report_table(output, :sum,    :title => "#{title} - sorted by sum")
        when :hits
          report_table(output, :hits,   :title => "#{title} - sorted by hits")
        else
          raise "Unknown duration report specified: #{report}!"
        end
      end

      output.puts
      output.puts "#{output.colorize(title, :white, :bold)} - observed total: " + output.colorize(display_value(sum_overall), :brown, :bold)
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Request traffic'
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories
    end
  end
end
