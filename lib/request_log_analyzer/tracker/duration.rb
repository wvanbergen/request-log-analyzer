module RequestLogAnalyzer::Tracker

  # Analyze the duration of a specific attribute
  #
  # === Options
  # * <tt>:amount</tt> The amount of lines in the report
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
  
      @categories = {}
    end

    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      if options[:multiple]
        categories = request.every(options[:category])
        durations  = request.every(options[:duration])
        
        if categories.length == durations.length
          categories.each_with_index do |category, index|
            @categories[category] ||= {:hits => 0, :cumulative => 0.0}
            @categories[category][:hits] += 1
            @categories[category][:cumulative] += durations[index]
          end
        else
          raise "Capture mismatch for multiple values in a request"
        end
      else
        category = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
        duration = options[:duration].respond_to?(:call) ? options[:duration].call(request) : request[options[:duration]]
  
        if duration.kind_of?(Float) && category.kind_of?(String)
          @categories[category] ||= {:hits => 0, :cumulative => 0.0, :min => duration, :max => duration }
          @categories[category][:hits] += 1
          @categories[category][:cumulative] += duration
          @categories[category][:min] = duration if duration < @categories[category][:min]
          @categories[category][:max] = duration if duration > @categories[category][:max]   
        end
      end
    end
    
    # Get the number of hits of a specific category.
    # <tt>cat</tt> The category
    def hits(cat)
      categories[cat][:hits]
    end
    
    # Get the total duration of a specific category.
    # <tt>cat</tt> The category
    def cumulative_duration(cat)
      categories[cat][:cumulative]
    end

    # Get the minimal duration of a specific category.
    # <tt>cat</tt> The category
    def min_duration(cat)
      categories[cat][:min]
    end

    # Get the maximum duration of a specific category.
    # <tt>cat</tt> The category
    def max_duration(cat)
      categories[cat][:max]
    end

    # Get the average duration of a specific category.
    # <tt>cat</tt> The category
    def average_duration(cat)
      categories[cat][:cumulative] / categories[cat][:hits]  
    end
    
    # Get the average duration of a all categories.
    def overall_average_duration
      overall_cumulative_duration / overall_hits
    end
    
    # Get the cumlative duration of a all categories.
    def overall_cumulative_duration
      categories.inject(0.0) { |sum, (name, cat)| sum + cat[:cumulative] }  
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
      sorted_by { |cat| cat[:cumulative] / cat[:hits] }
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
          rows << [cat, info[:hits], "%0.02fs" % info[:cumulative], "%0.02fs" % (info[:cumulative] / info[:hits]),
                    "%0.02fs" % info[:min], "%0.02fs" % info[:max]]
        end        
      end
    end

    # Generate a request duration report to the given output object
    # By default colulative and average duration are generated.
    # Any options for the report should have been set during initialize.
    # <tt>output</tt> The output object
    def report(output)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:cumulative, :average]
      options[:top]    ||= 20
  
      options[:report].each do |report|
        case report
        when :average
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time", :sort => :average) { |cat| cat[:cumulative] / cat[:hits] }  
        when :cumulative
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time", :sort => :cumulative) { |cat| cat[:cumulative] }
        when :hits
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits", :sort => :hits) { |cat| cat[:hits] }
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
