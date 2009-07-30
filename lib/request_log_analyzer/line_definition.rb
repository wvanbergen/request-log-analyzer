module RequestLogAnalyzer
  
  # The line definition class is used to specify what lines should be parsed from the log file.
  # It contains functionality to match a line against the definition and parse the information
  # from this line. This is used by the LogParser class when parsing a log file..
  class LineDefinition

    class Definer
      
      attr_accessor :line_definitions
      
      def initialize
        @line_definitions = {}
      end

      def initialize_copy(other)
        @line_definitions = other.line_definitions.dup
      end
      
      def method_missing(name, *args, &block)
        if block_given?
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.define(name, &block)
        else
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.new(name, args.first)
        end
      end
    end

    attr_reader :name
    attr_accessor :teaser, :regexp, :captures
    attr_accessor :header, :footer, :uniq
    
    # Initializes the LineDefinition instance with a hash containing the different elements of
    # the definition.
    def initialize(name, definition = {})
      @name     = name
      @captures = []
      definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
    end
        
    def self.define(name, &block)
      definition = self.new(name)
      yield(definition) if block_given?
      return definition
    end

    def pid_index
      @pid_index ||= begin
        captures.each_with_index {|cap, ix| @pid_index = ix if cap[:name] == :pid }
        @pid_index
      end
    end
    
    # Checks whether a given line matches this definition. 
    # It will return false if a line does not match. If the line matches, a hash is returned
    # with all the fields parsed from that line as content.
    # If the line definition has a teaser-check, a :teaser_check_failed warning will be emitted
    # if this teaser-check is passed, but the full regular exprssion does not ,atch.
    def matches(filename, line, lineno = nil, pos = nil, parser = nil)
      if @teaser.nil? || @teaser =~ line
        if match_data = line.match(@regexp)
          return { :line_definition => self, :lineno => lineno, :pos => pos, 
                   :filename => filename, :captures => match_data.captures,
                   :pid => (pid_index ? match_data.captures[pid_index].to_i : 0),
                   :hash => nil #Digest::SHA1.hexdigest(line)
                 }
        else
          if @teaser && parser
            parser.warn(:teaser_check_failed, "Teaser matched for #{name.inspect}, but full line did not:\n#{line.inspect}")
          end
          return false
        end
      else
        return false
      end
    end
    
    alias :=~ :matches

    def match_for(line, request, lineno = nil, parser = nil)
      if match_info = matches(line, lineno, parser)
        convert_captured_values(match_info[:captures], request)
      else
        false
      end
    end

    def convert_captured_values(values, request)
      value_hash = {}
      captures.each_with_index do |capture, index|
        converted = request.convert_value(values[index], capture)
        value_hash[capture[:name]] ||= converted
        if converted.kind_of?(Hash) && capture[:provides].kind_of?(Hash)
          capture[:provides].each do |name, type|
            value_hash[name] ||= request.convert_value(converted[name], { :type => type })
          end          
        end
      end
      return value_hash
    end

  end
  
end