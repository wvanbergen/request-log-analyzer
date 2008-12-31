module RequestLogAnalyzer::Filter
  
  class Timespan < Base
   
    attr_reader :before, :after
   
    def prepare
      # Convert the timestamp to the correct formats for quick timestamp comparisons
      @after  = @options[:after].strftime('%Y%m%d%H%M%S').to_i  if options[:after]     
      @before = @options[:before].strftime('%Y%m%d%H%M%S').to_i if options[:before]
    end
    
    def filter(request)
      (@after.nil? || @after <= request.timestamp) && (@before.nil? || @before > request.timestamp)
    end 
  end
  
end