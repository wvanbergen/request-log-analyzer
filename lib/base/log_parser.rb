module Base
  # Parse a log file
  class LogParser 

    LOG_LINES = {}
  
    # LogParser initializer
    # <tt>file</tt> The fileobject this LogParser wil operate on.
    def initialize(file, options = {})
      @file_name = file
      @options = options
      @file_size = File.size(@file_name)
    end
  
    def progress(&block)
      @progress_handler = block
    end

    # Output a warning
    # <tt>message</tt> The warning message (object)
    def warn(message)
      puts " -> " + message.to_s
    end  

    # Finds a log line and then parses the information in the line.
    # Yields a hash containing the information found. 
    # <tt>*line_types</tt> The log line types to look for (defaults to LOG_LINES.keys).
    # Yeilds a Hash when it encounters a chunk of information.
    def each(*line_types, &block)
      
      log_lines_hash = self.class::LOG_LINES
      
      # parse everything by default 
      line_types = log_lines_hash.keys if line_types.empty?

      File.open(@file_name) do |file|
      
        file.each_line do |line|
        
          @progress_handler.call(file.pos, @file_size) if @progress_handler
        
          line_types.each do |line_type|
            if log_lines_hash[line_type][:teaser] =~ line
              if log_lines_hash[line_type][:regexp] =~ line
                request = { :type => line_type, :line => file.lineno }
                log_lines_hash[line_type][:params].each do |key, value|
                  request[key] = case value
                    when Numeric; $~[value]
                    when Array;   $~[value.first].send(value.last)
                    else; nil
                  end
                
                end
                yield(request) if block_given?
              else
                warn("Unparsable #{line_type} line: " + line[0..79]) unless line_type == :failed
              end
            end            
          end
        end
        @progress_handler.call(:finished, @file_size) if @progress_handler
      end      
    end
  end
end