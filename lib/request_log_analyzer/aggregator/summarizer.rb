module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    attr_reader :trackers
    
    def initialize(format, options = {})
      super(format, options)
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
        tracker.update(request)
      end
    end
    
    def finalize
      @trackers.each { |tracker| tracker.finalize }
    end
       
    def report(color = false)
      report_header
      @trackers.each { |tracker| tracker.report(color) }
      report_footer      
    end
    
    def report_header
      puts "Summarizer results"
      puts "=============================="
    end
    
    def report_footer
      puts 
      puts "=============================="
      puts "Thanks for using request-log-analyzer"
      puts
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
      
      def report(color = false)
        puts self.inspect
        puts        
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
          puts '-' * options[:title].length
        end
        @categories.each { |cat, count| puts "#{cat}: #{count}" }
      end
    end
  end
end
