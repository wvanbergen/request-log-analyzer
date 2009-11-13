module RequestLogAnalyzer::Tracker

  # Get highest count of a specific attribute
  class Count < Base

    include RequestLogAnalyzer::Tracker::StatisticsTracking

    attr_reader :categories

    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:category]
      raise "No field to count has been set up #{self.inspect}" unless options[:field]

      @categorizer = create_lambda(options[:category])
      @counter     = create_lambda(options[:field])
      @categories  = {}
    end
    
    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      category = @categorizer.call(request)
      count    = @counter.call(request)
      update_statistics(category, count) if count.kind_of?(Numeric) && !category.nil?
    end

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
        
    # # Format an int to a nice string with decimal seperation.
    # def display_value(number)
    #   number.round.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    # end
    
    def display_value(count)
      return "-  " if count.nil?
      return "0  " if count.zero?
      case Math.log10(count).floor
      when  1...4  then '%d ' % count
      when  4...7  then '%dk' % (count / 1000)
      when  7...10 then '%dM' % (count / 1000_000)
      when 10...13 then '%dG' % (count / 1000_000_000)
      else              '%dT' % (count / 1000_000_000_000)
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Total'
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories
    end
  end
end
