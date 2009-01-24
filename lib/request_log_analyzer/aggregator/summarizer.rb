require File.dirname(__FILE__) + '/../tracker'

module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    class Definer
      
      attr_reader :trackers
      
      def initialize
        @trackers = []
      end
      
      def reset!
        @trackers = []
      end
      
      def method_missing(tracker_method, *args)
        track(tracker_method, args.first)
      end
      
      def frequency(category_field, options = {})
        if category_field.kind_of?(Symbol)
          track(:frequency, options.merge(:category => category_field))
        elsif category_field.kind_of?(Hash)
          track(:frequency, category_field.merge(options))
        end
      end
      
      def duration(duration_field, options = {})
        if duration_field.kind_of?(Symbol)
          track(:duration, options.merge(:duration => duration_field))
        elsif duration_field.kind_of?(Hash)
          track(:duration, duration_field.merge(options))        
        end
      end      
      
      def track(tracker_klass, options = {})
        tracker_klass = RequestLogAnalyzer::Tracker.const_get(RequestLogAnalyzer::to_camelcase(tracker_klass)) if tracker_klass.kind_of?(Symbol)
        @trackers << tracker_klass.new(options)
      end
    end
    
    attr_reader :trackers
    attr_reader :warnings_encountered
    
    def initialize(source, options = {})
      super(source, options)
      @warnings_encountered = {}
      @trackers = source.file_format.report_trackers
      setup
    end
    
    def setup
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
       
    def report(output)
      report_header(output)
      if source.parsed_requests > 0
        @trackers.each { |tracker| tracker.report(output) }
      else
        output.puts
        output.puts('There were no requests analyzed.')
      end
      report_footer(output)
    end
    
    def report_header(output)
      output.title("Request summary")
  
      output.with_style(:cell_separator => false) do 
        output.table({:width => 20}, {:font => :bold}) do |rows|
          rows << ['Parsed lines:',   source.parsed_lines]
          rows << ['Parsed request:', source.parsed_requests]
          rows << ['Skipped lines:',  source.skipped_lines]
        
          rows <<  ["Warnings:", @warnings_encountered.map { |(key, value)| "#{key.inspect}: #{value}" }.join(', ')] if has_warnings?
        end
      end
      output << "\n"
    end
    
    def report_footer(output)
      if has_serious_warnings?     
        
        output.title("Parse warnings")
        
        output.puts "Multiple warnings were encountered during parsing. Possibly, your logging "
        output.puts "is not setup correctly. Visit this website for logging configuration tips:"
        output.puts output.link("http://github.com/wvanbergen/request-log-analyzer/wikis/configure-logging")
        output.puts
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
  end
end
