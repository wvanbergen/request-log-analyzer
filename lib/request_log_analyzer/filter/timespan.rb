module RequestLogAnalyzer::Filter
  
  # Reject all requests not in given timespan
  # Options
  # * <tt>:after</tt> Only keep requests after this DateTime.
  # * <tt>:before</tt> Only keep requests before this DateTime.
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