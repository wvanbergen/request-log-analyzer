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

    attr_reader :categories

    # Check if duration and catagory option have been received,
    def prepare
      raise "No duration field set up for category tracker #{self.inspect}" unless options[:duration]
      raise "No categorizer set up for duration tracker #{self.inspect}" unless options[:category]

      @categorizer  = options[:category].respond_to?(:call) ? options[:category] : lambda { |request| request[options[:category]] }
      @durationizer = options[:duration].respond_to?(:call) ? options[:duration] : lambda { |request| request[options[:duration]] }
      @categories = {}
    end

    # Update sthe running calculation numbers with the newly found duration.
    # <tt>category</tt>:: The category for which to update the running calculations
    # <tt>duration</tt>:: The duration to update the calculations with.
    def update_numbers(category, duration)
      @categories[category] ||= {:hits => 0, :sum => 0.0, :mean => 0.0, :sum_of_squares => 0.0, :min => duration, :max => duration }
      delta = duration - @categories[category][:mean]

      @categories[category][:hits]           += 1
      @categories[category][:mean]           += (delta / @categories[category][:hits])
      @categories[category][:sum_of_squares] += delta * (duration - @categories[category][:mean])
      @categories[category][:sum]            += duration
      @categories[category][:min]             = duration if duration < @categories[category][:min]
      @categories[category][:max]             = duration if duration > @categories[category][:max]
    end

    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      if options[:multiple]
        categories = request.every(options[:category])
        durations  = request.every(options[:duration])
        raise "Capture mismatch for multiple values in a request" unless categories.length == durations.length
        categories.each_with_index { |category, index| update_numbers(category, durations[index]) }
      else
        category = @categorizer.call(request)
        duration = @durationizer.call(request)
        update_numbers(category, duration) if duration.kind_of?(Numeric) && !category.nil?
      end
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
      Math.sqrt(variance(cat)) rescue 0.0
    end

    # Get the variance of the duration of a specific category.
    # <tt>cat</tt> The category
    def variance(cat)
      categories[cat][:sum_of_squares] / (categories[cat][:hits] - 1) rescue 0.0
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
    def report_table(output, sort, options = {}, &block)
      amount = output.options[:amount] || 20
      output.title(options[:title])

      top_categories = sorted_by(sort)
      top_categories = top_categories.slice(0, amount) unless amount == :all
      output.table({:title => 'Category', :width => :rest},
            {:title => 'Hits',   :align => :right, :highlight => (sort == :hits),   :min_width => 4 },
            {:title => 'Sum',    :align => :right, :highlight => (sort == :sum),    :min_width => 6 },
            {:title => 'Mean',   :align => :right, :highlight => (sort == :mean),   :min_width => 6 },
            {:title => 'StdDev', :align => :right, :highlight => (sort == :stddev), :min_width => 6 },
            {:title => 'Min',    :align => :right, :highlight => (sort == :min),    :min_width => 6 },
            {:title => 'Max',    :align => :right, :highlight => (sort == :max),    :min_width => 6 }) do |rows|

        top_categories.each do |(cat, info)|
          rows << [cat, hits(cat), display_time(sum(cat)), display_time(mean(cat)), display_time(stddev(cat)),
                    display_time(min(cat)), display_time(max(cat))]
        end
      end
    end

    # Display a duration
    def display_time(time)
      time.nil? ? '-' : "%0.02fs" % time
    end

    # Generate a request duration report to the given output object
    # By default colulative and average duration are generated.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)

      sortings = output.options[:sort] || [:sum, :mean]

      sortings.each do |sorting|
        case sorting
        when :mean
          report_table(output, :mean,   :title => "#{title} - sorted by mean time")
        when :sum
          report_table(output, :sum,    :title => "#{title} - sorted by total time")
        when :stddev
          report_table(output, :stddev, :title => "#{title} - sorted by time variation")
        when :hits
          report_table(output, :hits,   :title => "#{title} - sorted by hits")
        else
          raise "Unknown duration report specified: #{report}!"
        end
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
