module RequestLogAnalyzer
  class LogParser
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :options
    attr_reader :current_request
    attr_reader :parsed_lines
    attr_reader :parsed_requests
    
    def initialize(format, options = {})      
      @line_definitions = {}
      @options          = options
      @parsed_lines     = 0
      @parsed_requests  = 0
      
      @current_io = nil
      
      # install the file format module (see RequestLogAnalyzer::FileFormat)
      # and register all the line definitions to the parser
      self.register_file_format(format)
    end
              
    def parse_files(files, options = {}, &block)
      files.each do |file|
        parse_file(file, options, &block)
      end
    end
    
    # Parses a file. 
    # Creates an IO stream for the provided file, and sends it to parse_io for further handling
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
      options[:line_types] ||= file_format.line_definitions.keys

      # check whether all provided line types are valid
      unknown = options[:line_types].reject { |line_type| file_format.line_definitions.has_key?(line_type) }
      raise "Unknown line types: #{unknown.join(', ')}" unless unknown.empty?
      
      @current_io = io
      @current_io.each_line do |line|
        
        @progress_handler.call(:progress, @current_io.pos) if @progress_handler && @current_io.lineno % 10 == 0
        
        request_data = nil
        if options[:line_types].detect { |line_type| request_data = file_format.line_definitions[line_type].matches(line, @current_io.lineno, self) }
          @parsed_lines += 1
          if @options[:combined_requests]
            update_current_request(request_data, &block)
          else
            handle_request(RequestLogAnalyzer::Request.create(@file_format, request_data), &block)
            @parsed_requests += 1
          end       
        end
      end
      
      warn(:unclosed_request, "End of file reached, but last request was not completed!") unless @current_request.nil?
  
      @current_io = nil
    end
    
    # Pass a block to this function to install a progress handler
    def on_progress(&block)
      @progress_handler = block
    end
    
    def on_warning(&block)
      @warning_handler = block
    end

    def warn(type, message)
      @warning_handler.call(type, message, @current_io.lineno) if @warning_handler
    end
    
    protected
    
    def update_current_request(request_data, &block)
      if header_line?(request_data)
        unless @current_request.nil?
          warn(:unclosed_request, "Encountered header line, but previous request was not closed!")
          @current_request = nil
        else
          @current_request = RequestLogAnalyzer::Request.create(@file_format, request_data)              
        end
      else
        unless @current_request.nil?
          @current_request << request_data
          if footer_line?(request_data)
            handle_request(@current_request, &block)
            @current_request = nil
            @parsed_requests += 1  
          end
        else
          warn(:no_current_request, "Parsebale line found outside of a request!")
        end
      end
    end
    
    def handle_request(request, &block)
      yield(request) if block_given?
    end
    
    def header_line?(hash)
      file_format.line_definitions[hash[:line_type]].header
    end
    
    def footer_line?(hash)
      file_format.line_definitions[hash[:line_type]].footer  
    end 
  end
end