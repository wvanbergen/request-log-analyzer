module RequestLogAnalyzer::Tracker

  # Analyze the duration of a specific attribute
  #
  # Options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:title</tt> Title do be displayed above the report  
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:duration</tt> The field containing the duration in the request hash.
  # * <tt>:amount</tt> The amount of lines in the report
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

    def prepare
      raise "No duration field set up for category tracker #{self.inspect}" unless options[:duration]
      raise "No categorizer set up for duration tracker #{self.inspect}" unless options[:category]
  
      @categories = {}
    end

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
  
        if !duration.nil? && !category.nil?
          @categories[category] ||= {:hits => 0, :cumulative => 0.0, :min => duration, :max => duration }
          @categories[category][:hits] += 1
          @categories[category][:cumulative] += duration
          @categories[category][:min] = duration if duration < @categories[category][:min]
          @categories[category][:max] = duration if duration > @categories[category][:max]   
        end
      end
    end
    
    def hits(cat)
      categories[cat][:hits]
    end
    
    def cumulative_duration(cat)
      categories[cat][:cumulative]
    end

    def min_duration(cat)
      categories[cat][:min]
    end

    def max_duration(cat)
      categories[cat][:max]
    end

    
    def average_duration(cat)
      categories[cat][:cumulative] / categories[cat][:hits]  
    end
    
    def overall_average_duration
      overall_cumulative_duration / overall_hits
    end
    
    def overall_cumulative_duration
      categories.inject(0.0) { |sum, (name, cat)| sum + cat[:cumulative] }  
    end
    
    def overall_hits
      categories.inject(0) { |sum, (name, cat)| sum + cat[:hits] }
    end

    def sorted_by_hits
      sorted_by(:hits)
    end

    def sorted_by_cumulative
      sorted_by(:cumulative)
    end

    def sorted_by_average
      sorted_by { |cat| cat[:cumulative] / cat[:hits] }
    end
          
    def sorted_by(by = nil) 
      if block_given?
        categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) } 
      else
        categories.sort { |a, b| b[1][by] <=> a[1][by] } 
      end
    end
    
    # Builds a result table using a provided sorting function 
    def report_table(output, amount = 10, options = {}, &block)
    
      output.title(options[:title])
    
      top_categories = @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount)
      output.table({:title => 'Category', :width => :rest}, {:title => 'Hits', :align => :right, :min_width => 4}, 
            {:title => 'Cumulative', :align => :right, :min_width => 10}, {:title => 'Average', :align => :right, :min_width => 8},
            {:title => 'Min', :align => :right}, {:title => 'Max', :align => :right}) do |rows|
      
        top_categories.each do |(cat, info)|
          rows << [cat, info[:hits], "%0.02fs" % info[:cumulative], "%0.02fs" % (info[:cumulative] / info[:hits]),
                    "%0.02fs" % info[:min], "%0.02fs" % info[:max]]
        end        
      end

    end

    def report(output)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:cumulative, :average]
      options[:top]    ||= 20
  
      options[:report].each do |report|
        case report
        when :average
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time") { |cat| cat[:cumulative] / cat[:hits] }  
        when :cumulative
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time") { |cat| cat[:cumulative] }
        when :hits
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits") { |cat| cat[:hits] }
        else
          raise "Unknown duration report specified: #{report}!"
        end
      end
    end      
  end
end
