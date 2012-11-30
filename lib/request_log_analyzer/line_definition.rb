module RequestLogAnalyzer

  # The line definition class is used to specify what lines should be parsed from the log file.
  # It contains functionality to match a line against the definition and parse the information
  # from this line. This is used by the LogParser class when parsing a log file..
  class LineDefinition

    class Definer

      attr_accessor :line_definitions

      def initialize
        @line_definitions = OrderedHash.new
      end

      def initialize_copy(other)
        @line_definitions = other.line_definitions.dup
      end
      
      def define_line(name, arg = {}, &block)
        if block_given?
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.define(name, &block)
        else
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.new(name, arg)
        end
      end

      def method_missing(name, *args, &block)
        define_line(name, args[0], &block)
      end
    end

    class CaptureDefiner
      attr_accessor :capture_hash
      
      def initialize(hash)
        @capture_hash = hash
      end
      
      def as(type, type_options = {})
        @capture_hash.merge!(type_options.merge(:type => type))
        return self
      end
    end

    attr_reader :name
    attr_accessor :teaser, :regexp, :captures, :compound
    attr_accessor :header, :footer

    alias_method :header?, :header
    alias_method :footer?, :footer

    # Initializes the LineDefinition instance with a hash containing the different elements of
    # the definition.
    def initialize(name, definition = {})
      @name     = name
      @captures = []
      @teaser   = nil
      @compound = []
      definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
    end

    def self.define(name, &block)
      definition = self.new(name)
      yield(definition) if block_given?
      return definition
    end
    
    def capture(name)
      new_capture_hash = OrderedHash.new()
      new_capture_hash[:name] = name
      new_capture_hash[:type] = :string
      captures << new_capture_hash
      CaptureDefiner.new(new_capture_hash)
    end
    
    def all_captured_variables
      captures.map { |c| c[:name] } + captures.map { |c| c[:provides] }.compact.map { |pr| pr.keys }.flatten
    end

    # Checks whether a given line matches this definition.
    # It will return false if a line does not match. If the line matches, a hash is returned
    # with all the fields parsed from that line as content.
    # If the line definition has a teaser-check, a :teaser_check_failed warning will be emitted
    # if this teaser-check is passed, but the full regular exprssion does not ,atch.
    def matches(line, &warning_handler)
      if @teaser.nil? || @teaser =~ line
        if match_data = line.match(@regexp)
          return { :line_definition => self, :captures => match_data.captures}
        else
          if @teaser && warning_handler
            warning_handler.call(:teaser_check_failed, "Teaser matched for #{name.inspect}, but full line did not:\n#{line.inspect}")
          end
          return false
        end
      else
        return false
      end
    rescue
      return false
    end

    alias :=~ :matches

    # matches the line and converts the captured values using the request's
    # convert_value function.
    def match_for(line, request, &warning_handler)
      if match_info = matches(line, &warning_handler)
        convert_captured_values(match_info[:captures], request)
      else
        false
      end
    end

    # Updates a captures hash using the converters specified in the request
    # and handle the :provides option in the line definition.
    def convert_captured_values(values, request)
      value_hash = {}
      captures.each_with_index do |capture, index|

        # convert the value using the request convert_value function
        converted = request.convert_value(values[index], capture)
        value_hash[capture[:name]] ||= converted

        # Add items directly to the resulting hash from the converted value
        # if it is a hash and they are set in the :provides hash for this line definition
        if converted.kind_of?(Hash) && capture[:provides].kind_of?(Hash)
          capture[:provides].each do |name, type|
            value_hash[name] ||= request.convert_value(converted[name], { :type => type })
          end
        end
      end
      return value_hash
    end

    # Returns true if this line captures values of the given name
    def captures?(name)
      all_captured_variables.include?(name)
    end
  end
end
