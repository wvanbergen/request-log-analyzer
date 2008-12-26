module RequestLogAnalyzer::Aggregator


  class Base
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :options
    
    def initialize(format, options = {})
      self.register_file_format(format)
      @options = options
    end
    
    def aggregate(request)
      # implement me!
    end
    
    
    def prepare
    end
    
    def finalize
    end
    
    def warning(type, message, lineno)
    end    

  end
end