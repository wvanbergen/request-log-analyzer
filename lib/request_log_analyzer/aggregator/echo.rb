module RequestLogAnalyzer::Aggregator

  # Echo Aggregator. Writes everything passed to it 
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
    
    def report(output)
      output.title("Warnings during parsing")
      output.puts @warnings
    end

  end
end