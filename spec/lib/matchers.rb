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

  class ParseLine
    
    def initialize(line)
      @line      = line
      @captures  = {}
      @line_type = nil
    end

    def failure_message
      @failure_message
    end

    def as(line_type)
      @line_type = line_type
      return self
    end
    
    def and_capture(captures)
      @captures = captures
      return self
    end

    def fail(message)
      @failure_message = message
      return false
    end

    def matches?(file_format)
      if @line_hash = file_format.parse_line(@line)
        if @line_type.nil? || @line_hash[:line_definition].name == @line_type
          @request   = file_format.request(@line_hash)
          @captures.each do |key, value|
            return fail("Expected line #{@line.inspect}\n    to capture #{key.inspect} as #{value.inspect} but was #{@request[key].inspect}.") if @request[key] != value
          end
          return true
        else
          return fail("The line should match the #{@line_type.inspect} line definition, but matched #{@line_hash[:line_definition].name.inspect} instead.")
        end
      else
        return fail("The line did not match any line definition.")
      end
    end
  end

  def have_line_definition(line_type)
    return HasLineDefinition.new(line_type)
  end

  def parse_line(line)
    ParseLine.new(line)
  end

end