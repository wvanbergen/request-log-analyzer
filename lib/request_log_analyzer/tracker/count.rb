module RequestLogAnalyzer::Tracker

  # Get highest count of a specific attribute
  class Count < Base

    attr_reader :categories, :categorizer

    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:category]
      @categorizer = create_lambda(options[:category])
      @categories   = {}
      
    end

    # Return the methods sorted by count
    def sorted_by_count
      @categories.sort { |a, b| b[1] <=> a[1] }
    end
    
    # Get the duration information fron the request and store it in the different categories.
    # <tt>request</tt> The request.
    def update(request)
      return if request[options[:category]] == 0 || request[options[:category]].nil?

      cat = @categorizer.call(request)
      if cat
        @categories[cat] ||= 0
        @categories[cat] += request[options[:category]].to_i
      end
    end

    def report(output)
      output.title(options[:title]) if options[:title]

      if @categories.empty?
        output << "None found.\n"
      else
        sorted_categories = output.slice_results(sorted_by_count)
        
        output.table({:title => "Category", :align => :right}, {:align => :right, :title => "Rows"}) do |rows|
          sorted_categories.each do |(cat, count)|
            rows << [cat, count]
          end
        end
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Count'
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories
    end
  end
end
