module RequestLogAnalyzer::Tracker

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

        adjuster = color ? 30 : 21 # justifcation calcultaion is slight different when color codes are inserterted
        max_cat_length = sorted_categories.map { |c| c[0].to_s.length }.max
        sorted_categories.each do |(cat, count)|
          text = "%-#{max_cat_length}s: %5d hits %s" % [cat, count, (green("(%0.01f%%)", color) % [(count.to_f / total_hits) * 100])]
          space_left  = report_width - (max_cat_length + adjuster + 3)
          bar_chars  = (space_left * (count.to_f / total_hits)).round
          puts "%-#{max_cat_length + adjuster}s %s%s" % [text, '┃', '░' * bar_chars]
        end
      end
    end

  end
end
