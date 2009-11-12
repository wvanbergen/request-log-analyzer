module RequestLogAnalyzer::Tracker

  # Get highest count of a specific attribute
  class Count < Base

    attr_reader :categories, :categorizer

    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:category]
      raise "No field to count has been set up #{self.inspect}" unless options[:field]
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
      return if request[options[:field]] == 0 || request[options[:field]].nil?

      cat = @categorizer.call(request)
      if cat
        @categories[cat] ||= 0
        @categories[cat] += request[options[:field]].to_i
      end
    end

    def report(output)
      if @categories.empty?
        output << "None found.\n"
      else
        output.title('')
        sorted_categories = output.slice_results(sorted_by_count)
        
        output.table( {:title => title, :align => :left,  :width => :rest },
                      {:title => "Count",         :align => :right, :width => 15    }) do |rows|
          sorted_categories.each do |(cat, count)|
            rows << [cat, format_number(count)]
          end
        end
      end
    end
    
    # Format an int to a nice string with decimal seperation.
    def format_number(number)
      number.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Category'
    end

    # Returns all the categories and the tracked duration as a hash than can be exported to YAML
    def to_yaml_object
      return nil if @categories.empty?
      @categories
    end
  end
end
