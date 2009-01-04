module RequestLogAnalyzer::Tracker

  # Catagorize requests.
  # Count and analyze requests for a specific attribute 
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return true for a request to be passed to the tracker.
  # * <tt>:title</tt> Title do be displayed above the report.
  # * <tt>:category</tt> Proc that handles the request categorization.
  # * <tt>:amount</tt> The amount of lines in the report
  #
  # The items in the update request hash are set during the creation of the Duration tracker.
  #
  # Example output:
  #
  #  HTTP methods
  #   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #  GET    ┃  22248 hits (46.2%) ┃░░░░░░░░░░░░░░░░░
  #  PUT    ┃  13685 hits (28.4%) ┃░░░░░░░░░░░
  #  POST   ┃  11662 hits (24.2%) ┃░░░░░░░░░
  #  DELETE ┃    512 hits (1.1%)  ┃
  class Category < RequestLogAnalyzer::Tracker::Base
  
    attr_reader :categories
  
    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:category]
      @categories = {}
      if options[:all_categories].kind_of?(Enumerable)
        options[:all_categories].each { |cat| @categories[cat] = 0 }
      end
    end
              
    def update(request)
      cat = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
      if !cat.nil? || options[:nils]
        @categories[cat] ||= 0
        @categories[cat] += 1
      end
    end
  
    def report(report_width, color = false)
      if options[:title]
        puts "\n#{options[:title]}" 
        puts green(('━' * report_width), color)
      end
    
      if @categories.empty?
        puts 'None found.'
      else
        sorted_categories = @categories.sort { |a, b| b[1] <=> a[1] }
        total_hits        = sorted_categories.inject(0) { |carry, item| carry + item[1] }
        sorted_categories = sorted_categories.slice(0...options[:amount]) if options[:amount]

        adjuster = color ? 33 : 24 # justifcation calcultaion is slight different when color codes are inserterted
        max_cat_length = [sorted_categories.map { |c| c[0].to_s.length }.max, report_width - adjuster].min
        sorted_categories.each do |(cat, count)|
          text = "%-#{max_cat_length+1}s┃%7d hits %s" % [cat.to_s[0..max_cat_length], count, (green("(%0.01f%%)", color) % [(count.to_f / total_hits) * 100])]
          space_left  = report_width - (max_cat_length + adjuster + 3)
          if space_left > 3
            bar_chars  = (space_left * (count.to_f / total_hits)).round
            puts "%-#{max_cat_length + adjuster}s %s%s" % [text, '┃', '░' * bar_chars]
          else
            puts text
          end
        end
      end
    end

  end
end
