module RequestLogAnalyzer::Aggregator

  class Echo < Base
    
    def aggregate(request)
      puts "\nRequest: " + request.inspect
    end
    
    def warning(type, message, lineno)
      puts "WARNING #{type.inspect} on line #{lineno}: #{message}"
    end

  end
end