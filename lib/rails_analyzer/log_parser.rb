require 'date'

module RailsAnalyzer
  class LogParser 

    LOG_LINES = {
        :started => {
              :teaser => /Processing/,
              :regexp => /Processing (\w+)#(\w+) \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/,
              :params => { :controller => 1, :action => 2, :ip => 3, :method => 5, :timestamp => 4  }
            },
        :completed => {
              :teaser => /Completed/,
              :regexp => /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/,
              :params => { :url => 7, :status => [6, :to_i], :duration => [1, :to_f], :rendering => [3, :to_f], :db => [5, :to_f] }
            }
      
    }
    
    attr_reader :open_errors
    attr_reader :close_errors
    
    def warn(message)
      puts " -> " + message.to_s
    end  
        
    def initialize(file)
      @file_name = file
    end

    def each(*line_types, &block)

      # parse everything by default 
      line_types = LOG_LINES.keys if line_types.empty?
      
      File.open(@file_name) do |file|
        file.each_line do |line|
          line_types.each do |line_type|
            
            if LOG_LINES[line_type][:teaser] =~ line
              if LOG_LINES[line_type][:regexp] =~ line
                request = { :type => line_type }
                LOG_LINES[line_type][:params].each do |key, value|
                  request[key] = case value
                    when Numeric; $~[value]
                    when Array;   $~[value.first].send(value.last)
                    else; nil
                  end
                end
                yield(request) if block_given?
              else
                warn("Unparsable #{line_type} line: " + line)
              end
            end
            
          end
        end
      end      
    end
  end
end