module RailsAnalyzer

  class LogParser < Base::LogParser
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
  end
end
