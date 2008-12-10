module RailsAnalyzer

  class LogParser < Base::LogParser
    
    # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
    RAILS_21_COMPLETED = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (?:\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(?:\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/

    # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]  
    RAILS_22_COMPLETED = /Completed in (\d+)ms \(View: (\d+), DB: (\d+)\) \| (\d\d\d).+\[(http.+)\]/
    
    
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
    
      :completed => {
        :teaser => /Completed/,
        :regexp => Regexp.new("(?:#{RAILS_21_COMPLETED}|#{RAILS_22_COMPLETED})"),
        :params => { :url => 5, :status => [4, :to_i], :duration => [1, :to_f], :rendering => [2, :to_f], :db => [3, :to_f] }
      }
    }
  end
end
