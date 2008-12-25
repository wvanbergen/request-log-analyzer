module RequestLogAnalyzer
  class LogParser
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :options
    attr_reader :line_definitions
    attr_reader :current_request
    
    def initialize(format, options = {})      
      @line_definitions = {}
      @options          = options
      @parsed_lines     = 0
      @parsed_requests  = 0
      
      # install the file format module (see RequestLogAnalyzer::FileFormat)
      # and register all the line definitions to the parser
      format_module = self.register_file_format(format)
      format_module::LINE_DEFINITIONS.each { |key, value| self[key] = value }
    end
          
    def []=(name, line_definition_hash)
      @line_definitions[name] = RequestLogAnalyzer::FileFormat::LineDefinition.new(name, line_definition_hash)
    end
    
    def valid_language?
      if @options[:combined_requests]
        @line_definitions.detect { |(name, ld)| ld.header } && @line_definitions.detect { |(name, ld)| ld.footer }
      else
        @line_definitions.length > 0
      end
    end
    
    def parse_file(file, options = {}, &block)
      @progress_handler.call(:started, file) if @progress_handler
      File.open(file, 'r') { |f| parse_io(f, options, &block) }
      @progress_handler.call(:completed, file) if @progress_handler
    end    

    # Finds a log line and then parses the information in the line.
    # Yields a hash containing the information found. 
    # <tt>*line_types</tt> The log line types to look for (defaults to LOG_LINES.keys).
    # Yeilds a Hash when it encounters a chunk of information.
    def parse_io(io, options = {}, &block)

      # parse every line type by default
      options[:line_types] ||= @line_definitions.keys
      unknown = options[:line_types].reject { |line_type| @line_definitions.has_key?(line_type) }
      raise "Unknown line types: #{unknown.join(', ')}" unless unknown.empty?
      
      io.each_line do |line|
        
        @progress_handler.call(:progress, @io.pos) if @progress_handler
        
        request_data = nil
        if options[:line_types].detect { |line_type| request_data = @line_definitions[line_type].matches(line, io.lineno) }
          @parsed_lines += 1
          if @options[:combined_requests]
            if header_line?(request_data)
              raise "Encountered header line on line #{request_data[:lineno]}, but previous request not closed" unless @current_request.nil?
              @current_request = RequestLogAnalyzer::Request.create(request_data)
            else
              raise "Parsebale line found outside of a request on line #{request_data[:lineno]} " if @current_request.nil?
              @current_request << request_data
              if footer_line?(request_data)
                yield(@current_request) if block_given?
                @current_request = nil
                @parsed_requests += 1  
              end
            end
          else
            yield(RequestLogAnalyzer::Request.create(request_data)) if block_given?
            @parsed_requests += 1
          end       
        end
      end
    end
    
    protected
    
    def header_line?(hash)
      @line_definitions[hash[:line_type]].header
    end
    
    def footer_line?(hash)
      @line_definitions[hash[:line_type]].footer  
    end    
  end
end