module RequestLogAnalyzer
  module FileFormat
    
    def file_format=(format)
      # Loads the module constant for built in file formats
      format = RequestLogAnalyzer::FileFormat.const_get(format.to_s.camelize) if format.kind_of?(Symbol)
      
      # register all the line definitions to the parser
      format::LINE_DEFINITIONS.each { |key, value| self[key] = value }
    end
    
    class LineDefinition

      attr_reader :name
      attr_accessor :teaser
      attr_accessor :regexp
      attr_accessor :captures
      attr_accessor :flags
      
      def initialize(name, definition = {})        
        @name = name
        definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
      end
      
      def convert_value(value, type)
        # TODO: fix me
        case type
        when :integer; value.to_i
        when :float;   value.to_f
        when :symbol;  value.to_sym
        else value
        end
      end
            
      def =~(line)
        if @teaser.nil? || @teaser =~ line
          if @regexp =~ line
            request_info = { :line_type => @name }
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
            puts "Teaser matched, but full line did not" unless @teaser.nil?
            return false
          end
        else
          return false
        end
      end
      
      alias :matches :=~
      
    end
  end
end