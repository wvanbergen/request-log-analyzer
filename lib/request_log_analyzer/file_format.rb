module RequestLogAnalyzer
  module FileFormat

    def self.included(base)
      base.send(:attr_reader, :file_format)
    end

    # Registers the correct language in the calling class (LogParser, Summarizer)
    def register_file_format(format_module)

      # Loads the module constant for built in file formats
      if format_module.kind_of?(Symbol)
        require "#{File.dirname(__FILE__)}/file_format/#{format_module}"
        format_module = RequestLogAnalyzer::FileFormat.const_get(format_module.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')) 
      end
      
      format_module.instance_eval do
        def line_definitions
          @line_definitions ||= self::LINE_DEFINITIONS.inject({}) do |hash, (name, definition)| 
            hash.merge!(name => LineDefinition.new(name, definition))
          end
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
    
    
    
    class LineDefinition

      attr_reader :name
      attr_accessor :teaser, :regexp, :captures
      attr_accessor :header, :footer
      
      def initialize(name, definition = {})
        @name = name
        definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
      end
      
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
            
      def matches(line, lineno = nil)
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
            # TODO: use Logger.warn
            # puts "Teaser matched, but full line did not" unless @teaser.nil?
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