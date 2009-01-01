module RequestLogAnalyzer::Aggregator

  class Echo < Base
    
    def prepare
      @warnings = ""
    end
    
    def aggregate(request)
      puts "\nRequest: " + request.inspect
    end
    
    def warning(type, message, lineno)
      @warnings << "WARNING #{type.inspect} on line #{lineno}: #{message}\n"
    end
    
    def report(report_width = 80, color = false)
      puts
      puts "Warnings during parsing:"
      puts green("━" * report_width, color)
      puts @warnings
    end

  end
end