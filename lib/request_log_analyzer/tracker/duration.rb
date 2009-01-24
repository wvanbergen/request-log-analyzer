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
            @categories[category] ||= {:count => 0, :total_duration => 0.0}
            @categories[category][:count] += 1
            @categories[category][:total_duration] += durations[index]
          end
        else
          raise "Capture mismatch for multiple values in a request"
        end
      else
        category = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
        duration = options[:duration].respond_to?(:call) ? options[:duration].call(request) : request[options[:duration]]
  
        if !duration.nil? && !category.nil?
          @categories[category] ||= {:count => 0, :total_duration => 0.0}
          @categories[category][:count] += 1
          @categories[category][:total_duration] += duration
        end
      end
    end

    def report_table(output, amount = 10, options = {}, &block)
    
      output.title(options[:title])
    
      top_categories = @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount)
      output.table({:title => 'Category', :width => :rest}, {:title => 'Hits', :align => :right, :min_width => 4}, 
            {:title => 'Cumulative', :align => :right, :min_width => 10}, {:title => 'Average', :align => :right, :min_width => 8}) do |rows|
      
        top_categories.each do |(cat, info)|
          rows << [cat, info[:count], "%0.02fs" % info[:total_duration], "%0.02fs" % (info[:total_duration] / info[:count])]
        end        
      end

    end

    def report(output)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:total, :average]
      options[:top]    ||= 20
  
      options[:report].each do |report|
        case report
        when :average
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time") { |request| request[:total_duration] / request[:count] }  
        when :total
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time") { |request| request[:total_duration] }
        when :hits
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits") { |request| request[:count] }
        else
          output << "Unknown duration report specified\n"
        end
      end
    end      
  end
end
