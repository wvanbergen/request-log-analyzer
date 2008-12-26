module RequestLogAnalyzer
  
  class Controller

    include RequestLogAnalyzer::FileFormat
    
    attr_reader :aggregators
    attr_reader :log_parser
    attr_reader :sources
    attr_reader :options

    def initialize(format = :rails, options = {})

      @options = options
      @aggregators = []
      @sources     = []
      
      register_file_format(format)  
      @log_parser  = RequestLogAnalyzer::LogParser.new(file_format)
    end
    
    def add_aggregator(agg)
      if agg.kind_of?(Symbol)
        require File.dirname(__FILE__) + "/aggregator/#{agg}"
        agg = RequestLogAnalyzer::Aggregator.const_get(agg.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join(''))
      end
      
      @aggregators << agg.new(file_format, @options)
    end
    
    alias :>> :add_aggregator
    
    def add_source(source)
      @sources << source
    end
    
    alias :<< :add_source
    
    def run
      
      @aggregators.each { |agg| agg.prepare }
      
      handle_request = Proc.new { |request| @aggregators.each { |agg| agg.aggregate(request) } }
      @sources.each do |source|
        case source
        when IO;     @log_parser.parse_io(source, options,   &handle_request) 
        when String; @log_parser.parse_file(source, options, &handle_request) 
        else;        raise "Unknwon source provided"
        end
      end
      
      @aggregators.each { |agg| agg.finalize }
      
    end
    
  end
end