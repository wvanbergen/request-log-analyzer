require 'date'

module RailsAnalyzer
  class LogParser 
  
    FIRST_LINE_REGEXP = /^Processing (\w+)#(\w+) \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/
    
    LAST_LINE_TEST    = /^Completed/
    LAST_LINE_REGEXP  = /^Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/
    
    attr_reader :open_errors
    attr_reader :close_errors
        
    def initialize(file)
      @file_name = file
    end

    def each_completed_request(&block)
      File.open(@file_name) do |file|
        file.each_line do |line|
          
          if LAST_LINE_TEST =~ line
            if LAST_LINE_REGEXP =~ line
              request = {:url => $7, :status => $6.to_i, :duration => $1.to_f, :rendering => $3.to_f, :db => $5.to_f}
              yield(request) if block_given?         
            else
              puts " -> Unparsable 'complete' line: " + line
            end
          end

        end
      end
    end

    def each_request(&block)
      File.open(@file_name) do |file|
        request = nil
        @open_errors = 0
        @close_errors = 0      

        file.each_line do |line|
          
          if FIRST_LINE_REGEXP =~ line
            @close_errors += 1 unless request.nil?  
            request = {:ip_address => $3, :controller => $1, :action => $2, :method => $5, :timestamp => DateTime.parse($4)}
          end
          
          if LAST_LINE_REGEXP =~ line
            if request.nil?
              @open_errors += 1 
            else 
              request[:duration] = $1.to_f
              yield request if block_given?
            end
          end
        end
      end
    end  
  end
  
end