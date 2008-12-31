module RequestLogAnalyzer::Filter
  
  class Field < Base
   
    attr_reader :field, :value, :mode
   
    def prepare
      # Convert the timestamp to the correct formats for quick timestamp comparisons
      @mode = (@options[:mode] || :accept).to_sym
      @field = @options[:field].to_sym
      @value = @options[:value] # convert value / regexp
    end
    
    def filter(request)
      case @mode
      when :select;   @value === request[@field]
      when :reject; !(@value === request[@field])
      end
    end 
  end
  
end