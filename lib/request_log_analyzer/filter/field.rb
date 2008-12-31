module RequestLogAnalyzer::Filter
  
  class Field < Base
   
    attr_reader :field, :value, :mode
   
    def prepare
      # Convert the timestamp to the correct formats for quick timestamp comparisons
      @mode = (@options[:mode] || :accept).to_sym
      @field = @options[:field].to_sym
      
      if @options[:value].kind_of?(String) && @options[:value][0, 1] == '/' && @options[:value][-1, 1] == '/'
        @value = Regexp.new(@options[:value][1..-2])
      else
        @value = @options[:value] # TODO: convert value?
      end
    end
    
    def filter(request)
      case @mode
      when :select;  request.every(@field).any? { |value| @value === value }
      when :reject; !request.every(@field).any? { |value| @value === value }
      end
    end 
  end
  
end