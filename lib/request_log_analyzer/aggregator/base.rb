module RequestLogAnalyzer::Aggregator

  # The base class of an aggregator. This class provides the interface to which
  # every aggregator should comply (by simply subclassing this class).
  #
  # When building an aggregator, do not forget that RequestLogAnalyzer can run in
  # single line mode or in combined requests mode. Make sure your aggregator can 
  # handle both cases, or raise an exception if RLA is rnning in the wrong mode.
  # Calling options[:combined_requests] tells you if RLA is running in combined 
  # requests mode, otherwise it is running in single line mode.
  class Base
    
    include RequestLogAnalyzer::FileFormat::Awareness
    
    attr_reader :options
    attr_reader :log_parser
    attr_reader :output
    
    # Intializes a new RequestLogAnalyzer::Aggregator::Base instance
    # It will include the specific file format module.
    def initialize(log_parser, options = {})
      @log_parser = log_parser
      self.register_file_format(log_parser.file_format)
      @options = options
      @output = options[:output] || STDOUT
    end

    # The prepare function is called just before parsing starts. This function 
    # can be used to initialie variables, etc.
    def prepare
    end
    
    # The aggregate function is called for every request.
    # Implement the aggregating functionality in this method
    def aggregate(request)
    end
    
    # The finalize function is called after all sources are parsed and no more
    # requests will be passed to the aggregator
    def finalize
    end
    
    # The warning method is called if the parser eits a warning.
    def warning(type, message, lineno)
    end    
    
    # The report function is called at the end. Implement any result reporting
    # in this function.
    def report(report_width = 80, color = false)
    end

  end
end