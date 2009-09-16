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

    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      category = @categorizer.call(request)
      traffic  = @trafficizer.call(request)

      if traffic.kind_of?(Numeric) && !category.nil?
        @categories[category] ||= {:hits => 0, :cumulative => 0, :min => traffic, :max => traffic }
        @categories[category][:hits] += 1
        @categories[category][:cumulative] += traffic
        @categories[category][:min] = traffic if traffic < @categories[category][:min]
        @categories[category][:max] = traffic if traffic > @categories[category][:max]
      end
    end
    
    # Get the number of hits of a specific category.
    # <tt>cat</tt> The category
    def hits(cat)
      categories[cat][:hits]
    end
    
    # Get the total duration of a specific category.
    # <tt>cat</tt> The category
    def cumulative_traffic(cat)
      categories[cat][:cumulative]
    end

    # Get the minimal duration of a specific category.
    # <tt>cat</tt> The category
    def min_traffic(cat)
      categories[cat][:min]
    end

    # Get the maximum duration of a specific category.
    # <tt>cat</tt> The category
    def max_traffic(cat)
      categories[cat][:max]
    end

    # Get the average duration of a specific category.
    # <tt>cat</tt> The category
    def average_traffic(cat)
      categories[cat][:cumulative].to_f / categories[cat][:hits]  
    end
    
    # Get the average duration of a all categories.
    def overall_average_traffic
      overall_cumulative_duration.to_f / overall_hits
    end
    
    # Get the cumlative duration of a all categories.
    def overall_cumulative_traffic
      categories.inject(0) { |sum, (name, cat)| sum + cat[:cumulative] }  
    end
    
    # Get the total hits of a all categories.
    def overall_hits
      categories.inject(0) { |sum, (name, cat)| sum + cat[:hits] }
    end

    # Return categories sorted by hits.
    def sorted_by_hits
      sorted_by(:hits)
    end

    # Return categories sorted by cumulative duration.
    def sorted_by_cumulative
      sorted_by(:cumulative)
    end

    # Return categories sorted by cumulative duration.
    def sorted_by_average
      sorted_by { |cat| cat[:cumulative].to_f / cat[:hits] }
    end
          
    # Return categories sorted by a given key.
    # <tt>by</tt> The key.
    def sorted_by(by = nil) 
      if block_given?
        categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) } 
      else
        categories.sort { |a, b| b[1][by] <=> a[1][by] } 
      end
    end
    
    # Block function to build a result table using a provided sorting function.
    # <tt>output</tt> The output object.
    # <tt>amount</tt> The number of rows in the report table (default 10).
    # === Options
    #  * </tt>:title</tt> The title of the table
    #  * </tt>:sort</tt> The key to sort on (:hits, :cumulative, :average, :min or :max)
    def report_table(output, amount = 10, options = {}, &block)
      
      output.title(options[:title])
      
      top_categories = @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount)
      output.table({:title => 'Category', :width => :rest}, 
            {:title => 'Hits',       :align => :right, :highlight => (options[:sort] == :hits), :min_width => 4}, 
            {:title => 'Cumulative', :align => :right, :highlight => (options[:sort] == :cumulative), :min_width => 10}, 
            {:title => 'Average',    :align => :right, :highlight => (options[:sort] == :average), :min_width => 8},
            {:title => 'Min',        :align => :right, :highlight => (options[:sort] == :min)}, 
            {:title => 'Max',        :align => :right, :highlight => (options[:sort] == :max)}) do |rows|
      
        top_categories.each do |(cat, info)|
          rows << [cat, info[:hits], format_traffic(info[:cumulative]), format_traffic((info[:cumulative] / info[:hits]).round),
                    format_traffic(info[:min]), format_traffic(info[:max])]
        end
      end
    end
    
    # Formats the traffic number using x B/kB/MB/GB etc notation
    def format_traffic(bytes)
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

      options[:report] ||= [:cumulative, :average]
      options[:top]    ||= 20
  
      options[:report].each do |report|
        case report
        when :average
          report_table(output, options[:top], :title => "#{title} - top #{options[:top]} by average", :sort => :average) { |cat| cat[:cumulative] / cat[:hits] }  
        when :cumulative
          report_table(output, options[:top], :title => "#{title} - top #{options[:top]} by sum", :sort => :cumulative) { |cat| cat[:cumulative] }
        when :hits
          report_table(output, options[:top], :title => "#{title} - top #{options[:top]} by hits", :sort => :hits) { |cat| cat[:hits] }
        else
          raise "Unknown duration report specified: #{report}!"
        end
      end
      
      output.puts
      output.puts "#{output.colorize(title, :white, :bold)} - observed total: " + output.colorize(format_traffic(overall_cumulative_traffic), :brown, :bold)
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
