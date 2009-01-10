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
    
    def report(output=STDOUT, report_width = 80, color = false)
      output << "\n"
      output << "Warnings during parsing:\n"
      output << green("━" * report_width, color) + "\n"
      output << @warnings + "\n"
    end

  end
end