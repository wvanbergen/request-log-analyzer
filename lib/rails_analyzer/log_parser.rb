# Jul 13 06:25:58 10.1.1.32 app_p [1957]: Processing EmployeeController#index (for 10.1.1.33 at 2008-07-13 06:25:58) [GET]
# Jul 13 06:25:58 10.1.1.32 app_p [1957]: Session ID: bd1810833653be11c38ad1e5675635bd
# Jul 13 06:25:58 10.1.1.32 app_p [1957]: Parameters: {"format"=>"xml", "action"=>"index}
# Jul 13 06:25:58 10.1.1.32 app_p [1957]: Rendering employees
# Jul 13 06:25:58 10.1.1.32 app_p [1957]: Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://example.com/employee.xml]

require 'date'

module RailsAnalyzer
  class LogParser 
  
    FIRST_LINE_REGEXP_QUICK   = /Processing/
    FIRST_LINE_REGEXP         = /Processing (\w+)#(\w+) \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/
    
    LAST_LINE_REGEXP_QUICK    = /Completed/
    LAST_LINE_REGEXP          = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/
    
    attr_reader :open_errors
    attr_reader :close_errors
        
    def initialize(file)
      @file_name = file
    end

    def each_completed_request(&block)
      File.open(@file_name) do |file|
        file.each_line do |line|

          if LAST_LINE_REGEXP_QUICK =~ line
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
    
    def each_processed_request(&block)
      File.open(@file_name) do |file|
        file.each_line do |line|

          if FIRST_LINE_REGEXP_QUICK =~ line
            if FIRST_LINE_REGEXP =~ line
              #@close_errors += 1 unless request.nil?
              request = {:controller => $1, :action => $2, :ip => $3, :method => $5.to_s, :timestamp => DateTime.parse($4)}
              yield(request) if block_given?         
            else
              puts " -> Unparsable 'processing' line: " + line
            end
          end

        end
      end
    
    end

    def each_request(&block)
      File.open(@file_name) do |file|
        file.each_line do |line|

          if LAST_LINE_REGEXP_QUICK =~ line
            if LAST_LINE_REGEXP =~ line
              request = {:url => $7, :status => $6.to_i, :duration => $1.to_f, :rendering => $3.to_f, :db => $5.to_f}
              yield(request) if block_given?         
            else
              puts " -> Unparsable 'complete' line: " + line
            end
          elsif FIRST_LINE_REGEXP_QUICK =~ line
            if FIRST_LINE_REGEXP =~ line
              #@close_errors += 1 unless request.nil?
              request = {:controller => $1, :action => $2, :ip => $3, :method => $5.to_s, :timestamp => DateTime.parse($4)}
              yield(request) if block_given?         
            else
              puts " -> Unparsable 'processing' line: " + line
            end
          end
        end
      end
    end
  end
  
end