#RuntimeError (Cannot destroy rule before it was created):     /app/models/rule.rb:198:in `destroy_on_period'     /v...n'     /usr/lib/ruby/gems/1.8/gems/mongrel-1.1.4/bin/mongrel_rails:281     /usr/bin/mongrel_rails:19:in `load'     /usr/bin/mongrel_rails:19
#ActiveRecord::StatementInvalid (Mysql::Error: Deadlock found when trying to get lock; try restarting transaction:  $
#ActiveRecord::StaleObjectError (Attempted to update a stale object):
#ArgumentError (invalid date):     /usr/lib/ruby/1.8/date.rb:931:in `new_by_frags'     /usr
require 'date'

module RailsAnalyzer
  # Parse a rails log file
  class LogParser 

    LOG_LINES = {
      :started => {
        :teaser => /Processing/,
        :regexp => /Processing (\w+)#(\w+) \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/,
        :params => { :controller => 1, :action => 2, :ip => 3, :method => 5, :timestamp => 4  }
      },
      :failed => {
        :teaser => /Error/,
        :regexp => /(\w+)Error \((.*)\)\:(.*)/,
        :params => { :error => 1, :exception_string => 2, :stack_trace => 3 }
      },
      :completed => {
        :teaser => /Completed/,
        :regexp => /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/,
        :params => { :url => 7, :status => [6, :to_i], :duration => [1, :to_f], :rendering => [3, :to_f], :db => [5, :to_f] }
      }
    }
    
    attr_reader :open_errors
    attr_reader :close_errors
    
    # LogParser initializer
    # <tt>file</tt> The fileobject this LogParser wil operate on.
    def initialize(file)
      @file_name = file
    end

    # Output a warning
    # <tt>message</tt> The warning message (object)
    def warn(message)
      puts " -> " + message.to_s
    end  

    # Finds a log line and then parses the information in the line.
    # Yields a hash containing the information found. 
    # <tt>*line_types</tt> The log line types to look for (defaults to LOG_LINES.keys).
    # Yeilds a Hash containing the information found in a line.
    def each(*line_types, &block)

      # parse everything by default 
      line_types = LOG_LINES.keys if line_types.empty?
      File.open(@file_name) do |file|
        file.each_line do |line|
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
                warn("Unparsable #{line_type} line: " + line[0..100]) unless line_type == :failed
              end
            end
            
          end
        end
      end      
    end
  end
end