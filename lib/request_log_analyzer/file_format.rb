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
            hash.merge!(name => RequestLogAnalyzer::LineDefinition.new(name, definition))
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
  end
end