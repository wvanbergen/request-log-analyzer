module RequestLogAnalyzer::Tracker

  class NumericValue < Base

    attr_reader :categories

    # Sets up the numeric value tracker. It will check whether the value and category
    # options are set that are used to extract and categorize the values during
    # parsing. Two lambda procedures are created for these tasks
    def prepare

      raise "No value field set up for numeric tracker #{self.inspect}" unless options[:value]
      raise "No categorizer set up for numeric tracker #{self.inspect}" unless options[:category]

      unless options[:multiple]
        @categorizer = create_lambda(options[:category])
        @valueizer   = create_lambda(options[:value])
      end
      
      @number_of_buckets = options[:number_of_buckets] || 1000
      @min_bucket_value  = options[:min_bucket_value] ? options[:min_bucket_value].to_f : 0.000001
      @max_bucket_value  = options[:max_bucket_value] ? options[:max_bucket_value].to_f : 1_000_000_000

      # precalculate the bucket size
      @bucket_size = (Math.log(@max_bucket_value) - Math.log(@min_bucket_value)) / @number_of_buckets.to_f

      @categories = {}
    end

    # Get the value information from the request and store it in the respective categories.
    #
    # If a request can contain multiple usable values for this tracker, the :multiple option
    # should be set to true. In this case, all the values and respective categories will be
    # read from the request using the #every method from the fields given in the :value and
    # :category option.
    #
    # If the request contains only one suitable value and the :multiple is not set, it will
    # read the single value and category from the fields provided in the :value and :category
    # option, or calculate it with any lambda procedure that is assigned to these options. The
    # request will be passed to procedure as input for the calculation.
    #
    # @param [RequestLogAnalyzer::Request] request The request to get the information from.
    def update(request)
      if options[:multiple]
        found_categories = request.every(options[:category])
        found_values     = request.every(options[:value])
        raise "Capture mismatch for multiple values in a request" unless found_categories.length == found_values.length

        found_categories.each_with_index do |cat, index|
          update_statistics(cat, found_values[index]) if cat && found_values[index].kind_of?(Numeric)
        end
      else
        category = @categorizer.call(request)
        value    = @valueizer.call(request)
        update_statistics(category, value) if (value.kind_of?(Numeric) || value.kind_of?(Array)) && category
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
          top_categories.each { |(category, _)| rows << statistics_row(category) }
        end
      end
    end

    # Display a value
    def display_value(value)
      return "- " if value.nil?
      return "0 " if value.zero?

      case [Math.log10(value.abs).floor, 0].max
        when  0...4  then '%d ' % value
        when  4...7  then '%dk' % (value / 1000)
        when  7...10 then '%dM' % (value / 1000_000)
        when 10...13 then '%dG' % (value / 1000_000_000)
        when 13...16 then '%dT' % (value / 1000_000_000_000)
        else              '%dP' % (value / 1000_000_000_000_000)
      end
    end

    # Generate a request report to the given output object
    # By default colulative and average duration are generated.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)
      sortings = output.options[:sort] || [:sum, :mean]
      sortings.each do |sorting|
        report_table(output, sorting, :title => "#{title} - by #{sorting}")
      end

      if options[:total]
        output.puts
        output.puts "#{output.colorize(title, :white, :bold)} - total: " + output.colorize(display_value(sum_overall), :brown, :bold)
      end
    end

    # Returns the title of this tracker for reports
    def title
      @title ||= begin
        if options[:title]
          options[:title]
        else
          title_builder = ""
          title_builder << "#{options[:value]} " if options[:value].kind_of?(Symbol)
          title_builder << (options[:category].kind_of?(Symbol) ? "per #{options[:category]}" : "per request")
          title_builder
        end
      end
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories.each do |cat, info|
        info[:stddev] = stddev(cat)
        info[:median] = median(cat) if info[:buckets]
        info[:interval_95_percent] = percentile_interval(cat, 95) if info[:buckets]
      end
      @categories
    end

    # Returns the bucket index for a value
    def bucket_index(value)
      return 0 if value < @min_bucket_value
      return @number_of_buckets - 1 if value >= @max_bucket_value

      ((Math.log(value) - Math.log(@min_bucket_value)) / @bucket_size).floor
    end

    # Returns the lower value of a bucket given its index
    def bucket_lower_bound(index)
      Math.exp((index * @bucket_size) + Math.log(@min_bucket_value))
    end

    # Returns the upper value of a bucket given its index
    def bucket_upper_bound(index)
      bucket_lower_bound(index + 1)
    end

    # Returns the average of the lower and upper bound of the bucket.
    def bucket_average_value(index)
      (bucket_lower_bound(index) + bucket_upper_bound(index)) / 2
    end

    # Returns a single value representing a bucket.
    def bucket_value(index, type = nil)
      case type
      when :begin, :start, :lower, :lower_bound; bucket_lower_bound(index)
      when :end, :finish, :upper, :upper_bound;  bucket_upper_bound(index)
      else bucket_average_value(index)
      end
    end

    # Returns the range of values for a bucket.
    def bucket_interval(index)
      Range.new(bucket_lower_bound(index), bucket_upper_bound(index), true)
    end

    # Records a hit on a bucket that includes the given value.
    def bucketize(category, value)
      @categories[category][:buckets][bucket_index(value)] += 1
    end

    # Returns the upper bound value that would include x% of the hits.
    def percentile_index(category, x, inclusive = false)
      total_encountered = 0
      @categories[category][:buckets].each_with_index do |count, index|
        total_encountered += count
        percentage = ((total_encountered.to_f / hits(category).to_f) * 100).floor
        return index if (inclusive && percentage >= x) || (!inclusive && percentage > x)
      end
    end

    def percentile_indices(category, start, finish)
      result = [nil, nil]
      total_encountered = 0
      @categories[category][:buckets].each_with_index do |count, index|
        total_encountered += count
        percentage = ((total_encountered.to_f / hits(category).to_f) * 100).floor
        if !result[0] && percentage > start
          result[0] = index
        elsif !result[1] && percentage >= finish
          result[1] = index
          return result
        end
      end
    end

    def percentile(category, x, type = nil)
      bucket_value(percentile_index(category, x, type == :upper), type)
    end
    
    
    def median(category)
      percentile(category, 50, :average)
    end

    # Returns a percentile interval, i.e. the lower bound and the upper bound of the values
    # that represent the x%-interval for the bucketized dataset.
    #
    # A 90% interval means that 5% of the values would have been lower than the lower bound and
    # 5% would have been higher than the upper bound, leaving 90% of the values within the bounds.
    # You can also provide a Range to specify the lower bound and upper bound percentages (e.g. 5..95).
    def percentile_interval(category, x)
      case x
      when Range
        lower, upper = percentile_indices(category, x.begin, x.end)
        Range.new(bucket_lower_bound(lower), bucket_upper_bound(upper))
      when Numeric
        percentile_interval(category, Range.new((100 - x) / 2, (100 - (100 - x) / 2)))
      else 
        raise 'What does it mean?'
      end
    end

    # Update the running calculation of statistics with the newly found numeric value.
    # <tt>category</tt>:: The category for which to update the running statistics calculations
    # <tt>number</tt>:: The numeric value to update the calculations with.
    def update_statistics(category, number)
      return number.map {|n| update_statistics(category, n)} if number.is_a?(Array)

      @categories[category] ||= { :hits => 0, :sum => 0, :mean => 0.0, :sum_of_squares => 0.0, :min => number, :max => number, 
                                  :buckets => Array.new(@number_of_buckets, 0) }
      
      delta = number - @categories[category][:mean]

      @categories[category][:hits]           += 1
      @categories[category][:mean]           += (delta / @categories[category][:hits])
      @categories[category][:sum_of_squares] += delta * (number - @categories[category][:mean])
      @categories[category][:sum]            += number
      @categories[category][:min]             = number if number < @categories[category][:min]
      @categories[category][:max]             = number if number > @categories[category][:max]

      bucketize(category, number)
    end

    # Get the number of hits of a specific category.
    # <tt>cat</tt> The category
    def hits(cat)
      @categories[cat][:hits]
    end

    # Get the total duration of a specific category.
    # <tt>cat</tt> The category
    def sum(cat)
      @categories[cat][:sum]
    end

    # Get the minimal duration of a specific category.
    # <tt>cat</tt> The category
    def min(cat)
      @categories[cat][:min]
    end

    # Get the maximum duration of a specific category.
    # <tt>cat</tt> The category
    def max(cat)
      @categories[cat][:max]
    end

    # Get the average duration of a specific category.
    # <tt>cat</tt> The category
    def mean(cat)
      @categories[cat][:mean]
    end

    # Get the standard deviation of the duration of a specific category.
    # <tt>cat</tt> The category
    def stddev(cat)
      Math.sqrt(variance(cat))
    end

    # Get the variance of the duration of a specific category.
    # <tt>cat</tt> The category
    def variance(cat)
      return 0.0 if @categories[cat][:hits] <= 1
      (@categories[cat][:sum_of_squares] / (@categories[cat][:hits] - 1))
    end

    # Get the average duration of a all categories.
    def mean_overall
      sum_overall / hits_overall
    end

    # Get the cumlative duration of a all categories.
    def sum_overall
      @categories.inject(0.0) { |sum, (_, cat)| sum + cat[:sum] }
    end

    # Get the total hits of a all categories.
    def hits_overall
      @categories.inject(0) { |sum, (_, cat)| sum + cat[:hits] }
    end

    # Return categories sorted by a given key.
    # <tt>by</tt> The key to sort on. This parameter can be omitted if a sorting block is provided instead
    def sorted_by(by = nil)
      if block_given?
        categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }
      else
        categories.sort { |a, b| send(by, b[0]) <=> send(by, a[0]) }
      end
    end

    # Returns the column header for a statistics table to report on the statistics result
    def statistics_header(options)
      [
        {:title => options[:title], :width => :rest},
        {:title => 'Hits',   :align => :right, :highlight => (options[:highlight] == :hits),   :min_width => 4},
        {:title => 'Sum',    :align => :right, :highlight => (options[:highlight] == :sum),    :min_width => 6},
        {:title => 'Mean',   :align => :right, :highlight => (options[:highlight] == :mean),   :min_width => 6},
        {:title => 'StdDev', :align => :right, :highlight => (options[:highlight] == :stddev), :min_width => 6},
        {:title => 'Min',    :align => :right, :highlight => (options[:highlight] == :min),    :min_width => 6},
        {:title => 'Max',    :align => :right, :highlight => (options[:highlight] == :max),    :min_width => 6},
        {:title => '95 %tile',    :align => :right, :highlight => (options[:highlight] == :percentile_interval),  :min_width => 11}
      ]
    end

    # Returns a row of statistics information for a report table, given a category
    def statistics_row(cat)
      [cat, hits(cat), display_value(sum(cat)), display_value(mean(cat)), display_value(stddev(cat)),
                display_value(min(cat)), display_value(max(cat)), 
                display_value(percentile_interval(cat, 95).begin) + '-' + display_value(percentile_interval(cat, 95).end) ]
    end
  end
end
