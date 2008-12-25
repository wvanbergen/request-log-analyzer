module RequestLogAnalyzer
  class LogParser
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :file_name
    attr_reader :file_size
    
    attr_reader :line_definitions
    
    def initialize(format, options = {})      
      @line_definitions = {}
      self.file_format = format
    end
          
    def parse_file(file, options = {}, &block)
      @progress_handler.call(:started, file) if @progress_handler
      File.open(file, 'r') { |f| parse_io(f, options, &block) }
      @progress_handler.call(:completed, file) if @progress_handler
    end
    
    def []=(name, line_definition_hash)
      @line_definitions[name] = RequestLogAnalyzer::FileFormat::LineDefinition.new(name, line_definition_hash)
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
        
        options[:line_types].each do |line_type|
          if request_data = @line_definitions[line_type].matches(line)
            request_data[:lineno] = io.lineno
            request = RequestLogAnalyzer::Request.new
            request << request_data 
            yield(request) if block_given?
          end            
        end
      end
    end
  end
end