require 'date'

module RailsAnalyzer
  # Parse a rails log file
  class LogParser 

    LOG_LINES = {
      # Processing EmployeeController#index (for 123.123.123.123 at 2008-07-13 06:00:00) [GET]
      :started => {
        :teaser => /Processing/,
        :regexp => /Processing (\w+)#(\w+) \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/,
        :params => { :controller => 1, :action => 2, :ip => 3, :timestamp => 4, :method => 5}
      },
      # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
      :failed => {
        :teaser => /Error/,
        :regexp => /(\w+)(Error|Invalid) \((.*)\)\:(.*)/,
        :params => { :error => 1, :exception_string => 3, :stack_trace => 4 }
      },
      # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
      :completed => {
        :teaser => /Completed/,
        :regexp => /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/,
        :params => { :url => 7, :status => [6, :to_i], :duration => [1, :to_f], :rendering => [3, :to_f], :db => [5, :to_f] }
      }
    }
    
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
      # parse everything by default 
      line_types = LOG_LINES.keys if line_types.empty?

      File.open(@file_name) do |file|
        
        file.each_line do |line|
          
          @progress_handler.call(file.pos, @file_size) if @progress_handler
          
          line_types.each do |line_type|
            if LOG_LINES[line_type][:teaser] =~ line
              if LOG_LINES[line_type][:regexp] =~ line
                request = { :type => line_type, :line => file.lineno }
                LOG_LINES[line_type][:params].each do |key, value|
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