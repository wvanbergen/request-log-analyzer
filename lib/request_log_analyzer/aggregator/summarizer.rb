module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    attr_reader :trackers
    attr_reader :warnings_encountered
    
    def initialize(log_parser, options = {})
      super(log_parser, options)
      @warnings_encountered = {}
      setup
    end
    
    def setup
      
    end
    
    def track(tracker_klass, options = {})
      @trackers ||= []
      tracker_klass = Summarizer.const_get(tracker_klass.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('') + "Tracker") if tracker_klass.kind_of?(Symbol)
      @trackers << tracker_klass.new(options)
    end
    
    def prepare
      raise "No trackers set up in Summarizer!" if @trackers.nil? || @trackers.empty?
      @trackers.each { |tracker| tracker.prepare }
    end
    
    def aggregate(request)
      @trackers.each do |tracker|
        tracker.update(request) if tracker.should_update?(request)
      end
    end
    
    def finalize
      @trackers.each { |tracker| tracker.finalize }
    end
       
    def report(color = false)
      report_header(color)
      @trackers.each { |tracker| tracker.report(color) }
      report_footer(color)
    end
    
    def report_header(color = false)
      puts "Summarizer results"
      puts green("==========================================================================", color)
      puts "Parsed lines:         #{green(log_parser.parsed_lines, color)}"
      puts "Parsed requests:      #{green(log_parser.parsed_requests, color)}" if options[:combined_requests]
      if has_warnings?
        puts "Warnings: " + @warnings_encountered.map { |(key, value)| "#{key.inspect}: #{blue(value, color)}" }.join(', ')
      end
    end
    
    def report_footer(color = false)
      puts 
      if has_serious_warnings?      
        puts green("==========================================================================", color)
        puts "Multiple warnings were encountered during parsing. Possibly, your logging "
        puts "is not setup correctly. Visit this website for logging configuration tips:"
        puts blue("http://github.com/wvanbergen/request-log-analyzer/wikis/configure-logging", color)
      end
    end
    
    def has_warnings?
       @warnings_encountered.inject(0) { |result, (key, value)| result += value } > 0
    end
    
    def has_serious_warnings?
      @warnings_encountered.inject(0) { |result, (key, value)| result += value } > 10
    end
    
    def warning(type, message, lineno)
      @warnings_encountered[type] ||= 0
      @warnings_encountered[type] += 1
    end
    
    class Tracker

      attr_reader :options
      
      def initialize(options ={})
        @options = options
      end
        
      def prepare
      end
      
      def update(request)
      end
      
      def finalize
      end
      
      def should_update?(request)
        return false if options[:line_type] && !request.has_line_type?(options[:line_type])
        
        if options[:if].kind_of?(Symbol)
          return false unless request[options[:if]]
        elsif options[:if].respond_to?(:call)
          return false unless options[:if].call(request)
        end
        
        if options[:unless].kind_of?(Symbol)
          return false if request[options[:unless]]
        elsif options[:unless].respond_to?(:call)
          return false if options[:unless].call(request)
        end        
        
        return true
      end
      
      def report(color = false)
        puts self.inspect
        puts        
      end
    end
    
    class DurationTracker < Tracker
      
      attr_reader :categories
      
      def prepare
        raise "No duration field set up for category tracker #{self.inspect}" unless options[:duration]
        raise "No categorizer set up for duration tracker #{self.inspect}" unless options[:category]
        
        @categories = {}
      end
      
      def update(request)
        category = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
        duration = options[:duration].respond_to?(:call) ? options[:duration].call(request) : request[options[:duration]]
        
        if !duration.nil? && !category.nil?
          @categories[category] ||= {:count => 0, :total_duration => 0.0}
          @categories[category][:count] += 1
          @categories[category][:total_duration] += duration
        end
      end
      
      def report_top(amount, options = {}, &block)
        if options[:title]
          puts
          puts "#{options[:title]}" 
          puts green('=' * options[:title].length, options[:color])
        end
        
        @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount).each do |(cat, info)|
          hits  = info[:count]
          total = "%-2.01f" % info[:total_duration]
          avg   = green(("(%-2.01fs avg)" % (info[:total_duration] / info[:count])) , options[:color])
          
          puts "%-50s: %6d hits - %6ss total %s" % [cat[0...40], hits, total, avg]
        end
      end
      
      def report(color = false)

        options[:title]  ||= 'Request duration'
        options[:report] ||= [:total, :average]
        options[:top]    ||= 20
        
        
        options[:report].each do |report|
          case report
          when :average
            report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time:", :color => color) { |request| request[:total_duration] / request[:count] }  
          when :total
            report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time:", :color => color) { |request| request[:total_duration] }
          when :hits
            report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits:", :color => color) { |request| request[:count] }
          else
            puts "Unknown duration report specified"
          end
        end
      end      
    end

    class TimespanTracker < Tracker
      
      attr_reader :first, :last
      
      def prepare
        raise "No categorizer set up for category tracker #{self.inspect}" unless options[:field]
      end
                  
      def update(request)
        timestamp = request[options[:field]]
        
        @first = timestamp if @first.nil? || @first < timestamp
        @last  = timestamp if @last.nil?  || @last > timestamp
      end
      
      def report(color = false)
        if options[:title]
          puts "\n#{options[:title]}" 
          puts '-' * options[:title].length
        end
        
        first_date  = DateTime.strptime(@first.to_s, '%Y%m%d%H%M%S')
        last_date   = DateTime.strptime(@last.to_s, '%Y%m%d%H%M%S')

        puts "First request:        #{first_date.strftime('%Y/%m/%d %H:%M:%I')}"
        puts "Last request:         #{last_date.strftime('%Y/%m/%d %H:%M:%I')}"        
        puts "Total time analyzed:  #{(@last && @first) ? (last_date - first_date).ceil : '-1' } days"
        puts ""
      end
    end
    
    class CategoryTracker < Tracker
      
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
      
      def report(color = false)
        if options[:title]
          puts "\n#{options[:title]}" 
          puts green(('=' * options[:title].length), color)
        end
        
        sorted_categories = @categories.sort { |a, b| b[1] <=> a[1] }
        total_hits     = sorted_categories.inject(0) { |carry, item| carry + item[1] }
                
        sorted_categories = sorted_categories.slice(0...options[:amount]) if options[:amount]
        max_cat_length = sorted_categories.map { |c| c[0].to_s.length }.max
        sorted_categories.each { |(cat, count)| 
          puts "%-#{max_cat_length}s: %5d hits %s" % [cat, count, (green("(%0.01f%%)", color) % [(count.to_f / total_hits) * 100])]
        }
      end
    end
  end
end
