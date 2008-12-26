module RequestLogAnalyzer::Aggregator

  class Echo < Base
    
    def aggregate(request)
      puts "Found request: " + request.inspect
    end

  end
end