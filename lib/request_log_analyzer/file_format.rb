module RequestLogAnalyzer
  module FileFormat

    # Add the file format attribute to the base class so that it can acccess the file format
    # definition.
    def self.included(base)
      base.send(:attr_reader, :file_format)
    end

    # Registers the correct language in the calling class (LogParser, Summarizer)
    # - It will load the correct file format module and assign it to the file_format attribute
    # - It will initialize all line definitions (accessible under file_format.line_definitions)
    # - It will include the hook module specific for the file format into the base class.
    def register_file_format(format_module)

      # Loads the module constant for built in file formats
      if format_module.kind_of?(Symbol)
        require "#{File.dirname(__FILE__)}/file_format/#{format_module}"
        format_module = RequestLogAnalyzer::FileFormat.const_get(format_module.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')) 
      end
      
      # Add some functions toe the file format module
      format_module.instance_eval do
        
        # creates LineDefinition instances for every key in the LINE_DEFINITIONS hash of the file format Module
        def line_definitions
          @line_definitions ||= self::LINE_DEFINITIONS.inject({}) do |hash, (name, definition)| 
            hash.merge!(name => LineDefinition.new(name, definition))
          end
        end
        
        # checks whether the file format definition is valid and can be used in combined requests mode.
        def valid?
          @line_definitions.detect { |(name, ld)| ld.header } && @line_definitions.detect { |(name, ld)| ld.footer }
        end
      end
      
      # register language specific hooks in base class
      hook_module = self.class.to_s.split('::').last
      if format_module.const_defined?(hook_module) && format_module.const_get(hook_module).kind_of?(Module)
        metaclass = (class << self; self; end)
        metaclass.send(:include, format_module.const_get(hook_module))
      end
      
      @file_format = format_module
    end
    
    
    # The line definition class is used to specify what lines should be parsed from the log file.
    # It contains functionality to match a line against the definition and parse the information
    # from this line. This is used by the LogParser class when parsing a log file..
    class LineDefinition

      attr_reader :name
      attr_accessor :teaser, :regexp, :captures
      attr_accessor :header, :footer
      
      # Initializes the LineDefinition instance with a hash containing the different elements of
      # the definition.
      def initialize(name, definition = {})
        @name = name
        definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
      end
      
      # Converts a parsed value (String) to the desired value using some heuristics.
      def convert_value(value, type)
        case type
        when :integer;   value.to_i
        when :float;     value.to_f
        when :decimal;   value.to_f          
        when :symbol;    value.to_sym
        when :sec;       value.to_f
        when :msec;      value.to_f / 1000
        when :timestamp; value.to_s # TODO: fix me?          
        else value
        end
      end
      
      # Checks whether a given line matches this definition. 
      # It will return false if a line does not match. If the line matches, a hash is returned
      # with all the fields parsed from that line as content.
      # If the line definition has a teaser-check, a :teaser_check_failed warning will be emitted
      # if this teaser-check is passed, but the full regular exprssion does not ,atch.
      def matches(line, lineno = nil, parser = nil)
        if @teaser.nil? || @teaser =~ line
          if @regexp =~ line
            request_info = { :line_type => name, :lineno => lineno }
            captures_found = $~.captures
            captures.each_with_index do |param, index|
              unless captures_found[index].nil? || param == :ignore
                # there is only one key/value pair in the param hash, each will only be called once
                param.each { |key, type| request_info[key] = convert_value(captures_found[index], type) }
              end
            end
            return request_info
          else
            parser.warn(:teaser_check_failed, "Teaser matched for #{name.inspect}, but full line did not:\n#{line.inspect}")  unless @teaser.nil? || parser.nil?
            return false
          end
        else
          return false
        end
      end
      
      alias :=~ :matches
      
    end
  end
end