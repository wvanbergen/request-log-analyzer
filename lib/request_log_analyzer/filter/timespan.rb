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
      return nil unless request
      
      if @after && @before && request.timestamp <= @before && @after <= request.timestamp
        return request
      elsif @after && @before.nil? && @after <= request.timestamp
        return request
      elsif @before && @after.nil? && request.timestamp <= @before 
        return request
      end

      return nil
    end 
  end
  
end