module RequestLogAnalyzer::Spec::Matchers
  
  class HasLineDefinition
    
    def initialize(line_type)
      @line_type = line_type.to_sym
      @captures  = []
    end
      
    def capturing(*captures)
      @captures += captures
      return self
    end
    
    def matches?(file_format)
      file_format = file_format.create if file_format.kind_of?(Class)
      if ld = file_format.line_definitions[@line_type]
        @captures.all? { |c| ld.captures.map { |cd| cd[:name] }.include?(c) }
      else
        false
      end
    end
  end
  
  class Parse
    def initialize(line)
      @line     = line
      @captures = nil
    end
    
    def failure_message
      message = "expected to parse the provided line"
      if @found_captures
        message << "with captures #{@captures.inspect}, but captured #{@found_captures.inspect}"
      end
      return message
    end
    
    def capturing(*captures)
      @captures = captures
      return self
    end
    
    def matches?(line_definition)
      hash = line_definition.matches(@line)
      if hash
        @found_captures = hash[:captures].to_a
        @captures.nil? ? true : @found_captures.eql?(@captures)
      else
        return false
      end
    end
  end
  
  def have_line_definition(line_type)
    return HasLineDefinition.new(line_type)
  end
  
  def parse(line)
    Parse.new(line)
  end
  
end