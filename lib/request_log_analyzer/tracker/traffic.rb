module RequestLogAnalyzer::Tracker

  # Analyze the average and total traffic of requests
  #
  # === Options
  # * <tt>:amount</tt> The amount of lines in the report
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:traffic</tt> The field containing the duration in the request hash.
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:title</tt> Title do be displayed above the report
  # * <tt>:unless</tt> Handle request if this proc is false for the handled request.
  class Traffic < Base

    attr_reader :categories

    # Check if duration and catagory option have been received,
    def prepare
      raise "No traffic field set up for category tracker #{self.inspect}" unless options[:traffic]
      raise "No categorizer set up for duration tracker #{self.inspect}" unless options[:category]

      @categorizer = options[:category].respond_to?(:call) ? options[:category] : lambda { |request| request[options[:category]] }
      @trafficizer = options[:traffic].respond_to?(:call)  ? options[:traffic]  : lambda { |request| request[options[:traffic]]  }
      @categories = {}
    end

    # Update sthe running calculation numbers with the newly found duration.
    # <tt>category</tt>:: The category for which to update the running calculations
    # <tt>duration</tt>:: The duration to update the calculations with.
    def update_numbers(category, traffic)
      @categories[category] ||= {:hits => 0, :sum => 0, :mean => 0.0, :sum_of_squares => 0.0, :min => traffic, :max => traffic }
      delta = traffic - @categories[category][:mean]

      @categories[category][:hits]           += 1
      @categories[category][:mean]           += (delta / @categories[category][:hits])
      @categories[category][:sum_of_squares] += delta * (traffic - @categories[category][:mean])
      @categories[category][:sum]            += traffic
      @categories[category][:min]             = traffic if traffic < @categories[category][:min]
      @categories[category][:max]             = traffic if traffic > @categories[category][:max]
    end

    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      category = @categorizer.call(request)
      traffic  = @trafficizer.call(request)

      update_numbers(category, traffic) if traffic.kind_of?(Numeric) && !category.nil?
    end

    # Get the number of hits of a specific category.
    # <tt>cat</tt> The category
    def hits(cat)
      categories[cat][:hits]
    end

    # Get the total duration of a specific category.
    # <tt>cat</tt> The category
    def sum(cat)
      categories[cat][:sum]
    end

    # Get the minimal duration of a specific category.
    # <tt>cat</tt> The category
    def min(cat)
      categories[cat][:min]
    end

    # Get the maximum duration of a specific category.
    # <tt>cat</tt> The category
    def max(cat)
      categories[cat][:max]
    end

    # Get the average duration of a specific category.
    # <tt>cat</tt> The category
    def mean(cat)
      categories[cat][:mean]
    end

    # Get the standard deviation of the duration of a specific category.
    # <tt>cat</tt> The category
    def stddev(cat)
      Math.sqrt(variance(cat)) rescue nil
    end

    # Get the variance of the duration of a specific category.
    # <tt>cat</tt> The category
    def variance(cat)
      categories[cat][:sum_of_squares] / (categories[cat][:hits] - 1) rescue nil
    end

    # Get the average duration of a all categories.
    def mean_overall
      sum_overall / hits_overall
    end

    # Get the cumlative duration of a all categories.
    def sum_overall
      categories.inject(0.0) { |sum, (name, cat)| sum + cat[:sum] }
    end

    # Get the total hits of a all categories.
    def hits_overall
      categories.inject(0) { |sum, (name, cat)| sum + cat[:hits] }
    end

    # Return categories sorted by a given key.
    # <tt>by</tt> The key.
    def sorted_by(by = nil)
      if block_given?
        categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }
      else
        categories.sort { |a, b| send(by, b[0]) <=> send(by, a[0]) }
      end
    end

    # Block function to build a result table using a provided sorting function.
    # <tt>output</tt> The output object.
    # <tt>amount</tt> The number of rows in the report table (default 10).
    # === Options
    #  * </tt>:title</tt> The title of the table
    #  * </tt>:sort</tt> The key to sort on (:hits, :cumulative, :average, :min or :max)
    def report_table(output, sort, amount = 10, options = {}, &block)

      output.title(options[:title])

      top_categories =       top_categories = sorted_by(sort).slice(0...amount)
      output.table({:title => 'Category', :width => :rest},
            {:title => 'Hits',   :align => :right, :highlight => (sort == :hits),   :min_width => 4},
            {:title => 'Sum',    :align => :right, :highlight => (sort == :sum),    :min_width => 6},
            {:title => 'Mean',   :align => :right, :highlight => (sort == :mean),   :min_width => 6},
            {:title => 'StdDev', :align => :right, :highlight => (sort == :stddev), :min_width => 6},
            {:title => 'Min',    :align => :right, :highlight => (sort == :min),    :min_width => 6},
            {:title => 'Max',    :align => :right, :highlight => (sort == :max),    :min_width => 6}) do |rows|

        top_categories.each do |(cat, info)|
          rows << [cat, hits(cat), display_traffic(sum(cat)), display_traffic(mean(cat)), display_traffic(stddev(cat)),
                    display_traffic(min(cat)), display_traffic(max(cat))]
        end
      end
    end

    # Formats the traffic number using x B/kB/MB/GB etc notation
    def display_traffic(bytes)
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

      options[:report] ||= [:sum, :mean]
      options[:top]    ||= 20

      options[:report].each do |report|
        case report
        when :mean
          report_table(output, :mean,   options[:top], :title => "#{title} - top #{options[:top]} by mean")
        when :stddev
          report_table(output, :stddev, options[:top], :title => "#{title} - top #{options[:top]} by standard deviation")
        when :sum
          report_table(output, :sum,    options[:top], :title => "#{title} - top #{options[:top]} by sum")
        when :hits
          report_table(output, :hits,   options[:top], :title => "#{title} - top #{options[:top]} by hits")
        else
          raise "Unknown duration report specified: #{report}!"
        end
      end

      output.puts
      output.puts "#{output.colorize(title, :white, :bold)} - observed total: " + output.colorize(display_traffic(sum_overall), :brown, :bold)
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
