module RequestLogAnalyzer::Aggregator

  class Echo < Base
    
    def aggregate(request)
      puts "\nRequest: " + request.inspect
    end

  end
end