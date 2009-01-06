require File.dirname(__FILE__) + '/../tracker/base'

module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    class Definer
      
      attr_reader :trackers
      
      def initialize
        @trackers = []
      end
      
      def method_missing(tracker_method, *args)
        track(tracker_method, args.first)
      end
      
      def category(category_field, options = {})
        if category_field.kind_of?(Symbol)
          track(:category, options.merge(:category => category_field))
        elsif category_field.kind_of?(Hash)
          track(:category, category_field.merge(options))
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
        require "#{File.dirname(__FILE__)}/../tracker/#{tracker_klass}"
        tracker_klass = RequestLogAnalyzer::Tracker.const_get(tracker_klass.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')) if tracker_klass.kind_of?(Symbol)
        @trackers << tracker_klass.new(options)
      end
    end
    
    attr_reader :trackers
    attr_reader :warnings_encountered
    
    def initialize(log_parser, options = {})
      super(log_parser, options)
      @warnings_encountered = {}
      @trackers = log_parser.file_format.report_trackers
      setup
    end
    
    def setup
    end
    
    def prepare
      raise "No trackers set up in Summarizer!" if @trackers.nil? || @trackers.empty?
      @trackers.each { |tracker| tracker.prepare }
      @trackers.each { |tracker| tracker.set_output(@output) }
    end
    
    def aggregate(request)
      @trackers.each do |tracker|
        tracker.update(request) if tracker.should_update?(request)
      end
    end
    
    def finalize
      @trackers.each { |tracker| tracker.finalize }
    end
       
    def report(report_width = 80, color = false)
      report_header(report_width, color)
      if log_parser.parsed_requests - log_parser.skipped_requests > 0
        @trackers.each { |tracker| tracker.report(report_width, color) }
      else
        @output << "\n"
        @output << "There were no requests analyzed.\n"
      end
      report_footer(report_width, color)
    end
    
    def report_header(report_width = 80, color = false)
      @output << "Request summary\n"
      @output << green("━" * report_width, color) + "\n"
      @output << "Parsed lines:         #{green(log_parser.parsed_lines, color)}\n"
      @output << "Parsed requests:      #{green(log_parser.parsed_requests, color)}\n"  if options[:combined_requests]
      @output << "Skipped requests:     #{green(log_parser.skipped_requests, color)}\n" if log_parser.skipped_requests > 0
      if has_warnings?
        @output <<  "Warnings:             " + @warnings_encountered.map { |(key, value)| "#{key.inspect}: #{blue(value, color)}" }.join(', ') + "\n"
      end
      @output << "\n"
    end
    
    def report_footer(report_width = 80, color = false)
      @output << "\n" 
      if has_serious_warnings?      
        @output << green("━" * report_width, color) + "\n"
        @output << "Multiple warnings were encountered during parsing. Possibly, your logging " + "\n"
        @output << "is not setup correctly. Visit this website for logging configuration tips:" + "\n"
        @output <<  blue("http://github.com/wvanbergen/request-log-analyzer/wikis/configure-logging", color) + "\n"
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
