module RailsAnalyzer

  class LogParser < Base::LogParser
    
    # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
    RAILS_21_COMPLETED = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (?:\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(?:\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/

    # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]  
    RAILS_22_COMPLETED = /Completed in (\d+)ms \((?:View: (\d+), )?DB: (\d+)\) \| (\d\d\d).+\[(http.+)\]/
    
    
    LOG_LINES = {
      # Processing EmployeeController#index (for 123.123.123.123 at 2008-07-13 06:00:00) [GET]
      :started => {
        :teaser => /Processing/,
        :regexp => /Processing ((?:\w+::)?\w+)#(\w+)(?: to (\w+))? \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/,
        :params => [{:controller => :string}, {:action => :string}, {:format => :string}, {:ip => :string}, {:timestamp => :timestamp}, {:method => :string}]
      },
      # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
      :failed => {
        :teaser => /Error/,
        :regexp => /(\w+)(?:Error|Invalid) \((.*)\)\:(.*)/,
        :params => [{:error => :string}, {:exception_string => :string}, {:stack_trace => :string}]
      },
    
      :completed => {
        :teaser   => /Completed in /,
        :regexp   => Regexp.new("(?:#{RAILS_21_COMPLETED}|#{RAILS_22_COMPLETED})"),
        :params   => [{:duration => :sec},  {:rendering => :sec},  {:db => :sec},  {:status => :int}, {:url => :string},  # 2.1 variant 
                      {:duration => :msec}, {:rendering => :msec}, {:db => :msec}, {:status => :int}, {:url => :string}]  # 2.2 variant 

      }
    }
  end
end
