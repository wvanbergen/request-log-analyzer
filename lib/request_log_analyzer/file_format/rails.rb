module RequestLogAnalyzer::FileFormat::Rails

  # Rails < 2.1 completed line example
  # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
  RAILS_21_COMPLETED = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (?:\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(?:\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/

  # Rails > 2.1 completed line example
  # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]  
  RAILS_22_COMPLETED = /Completed in (\d+)ms \((?:View: (\d+), )?DB: (\d+)\) \| (\d\d\d).+\[(http.+)\]/


  LINE_DEFINITIONS = {
    
    # Processing EmployeeController#index (for 123.123.123.123 at 2008-07-13 06:00:00) [GET]
    :started => {
      :header => true,
      :teaser => /Processing/,
      :regexp => /Processing ((?:\w+::)?\w+)#(\w+)(?: to (\w+))? \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/,
      :captures => [{ :name => :controller, :type => :string }, 
                    { :name => :action,     :type  => :string }, 
                    { :name => :format,     :type  => :string }, 
                    { :name => :ip,         :type  => :string, :anonymize => :ip }, 
                    { :name => :timestamp,  :type  => :timestamp, :anonymize => :slightly }, 
                    { :name => :method,     :type  => :string }]
    },

    # Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.
    :cache_hit => {
      :regexp   => /Filter chain halted as \[\#<ActionController::Caching::Actions::ActionCacheFilter:.+>\] rendered_or_redirected/,
      :captures => []
    },
    
    # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
    :failed => {
      :footer => true,   
      :teaser => /Error/,
      :regexp => /(\w+Error|\w+Invalid) \((.*)\)\:(.*)/,
      :captures => [{ :name => :error,            :type => :string}, 
                    { :name => :exception_string, :type => :string}, 
                    { :name => :stack_trace,      :type => :string, :anonymize => true}]
    },

    # Completed lines: see above. Parse both completed line formats
    :completed => {
      :footer   => true,
      :teaser   => /Completed in /,
      :regexp   => Regexp.new("(?:#{RAILS_21_COMPLETED}|#{RAILS_22_COMPLETED})"),
      :captures => [{ :name => :duration, :type => :sec, :anonymize => :slightly }, 
                    { :name => :view,     :type => :sec, :anonymize => :slightly },  
                    { :name => :db,       :type => :sec, :anonymize => :slightly },  
                    { :name => :status,   :type => :integer }, 
                    { :name => :url,      :type => :string, :anonymize => :url },  # 2.1 variant 
                    { :name => :duration, :type => :msec, :anonymize => :slightly }, 
                    { :name => :view,     :type => :msec, :anonymize => :slightly }, 
                    { :name => :db,       :type => :msec, :anonymize => :slightly }, 
                    { :name => :status,   :type => :integer}, 
                    { :name => :url,      :type => :string, :anonymize => :url }]  # 2.2 variant 

    }
  }   
  
  module Summarizer
    
    def setup
      track(:timespan, :field => :timestamp, :line_type => :started)      
      track(:category, :category => REQUEST_CATEGORIZER, :title => 'Top 20 hits', :amount => 20, :line_type => :started)
      track(:category, :category => :method, :title => 'HTTP methods')
      track(:category, :category => :status, :title => 'HTTP statuses returned')
      track(:category, :category => lambda { |request| request =~ :cache_hit ? 'Cache hit' : 'No hit' }, :title => 'Rails action cache hits')
      
      track(:duration, :duration => :duration, :category => REQUEST_CATEGORIZER, :title => "Request duration",    :line_type => :completed)
      track(:duration, :duration => :view,     :category => REQUEST_CATEGORIZER, :title => "Database time",       :line_type => :completed)
      track(:duration, :duration => :db,       :category => REQUEST_CATEGORIZER, :title => "View rendering time", :line_type => :completed)
      
      track(:category, :category => REQUEST_CATEGORIZER, :title => 'Process blockers (> 1 sec duration)', :line_type => :completed,
              :if => lambda { |request| request[:duration] > 1.0 }, :amount => 20)
              
      track(:hourlyspread, :field => :timestamp, :line_type => :started)      
      track(:category, :category => :error, :title => 'Failed requests', :line_type => :failed, :amount => 20)              
    end
    
    REQUEST_CATEGORIZER = Proc.new do |request|
      if request.combined?
      
        if request =~ :failed
          format = request[:format] || 'html'
          "#{request[:error]} in #{request[:controller]}##{request[:action]}.#{format} [#{request[:method]}]"
        else
          format = request[:format] || 'html'
          "#{request[:controller]}##{request[:action]}.#{format} [#{request[:method]}]"
        end
      
      else
        case request.line_type
        when :started   
          format = request[:format] || 'html'
          "#{request[:controller]}##{request[:action]}.#{format} [#{request[:method]}]"
        
        when :completed
          url = request[:url].downcase.split(/^http[s]?:\/\/[A-z0-9\.-]+/).last.split('?').first # only the relevant URL part
          url << '/' if url[-1] != '/'[0] && url.length > 1 # pad a trailing slash for consistency

          url.gsub!(/\/\d+-\d+-\d+(\/|$)/, '/:date/') # Combine all (year-month-day) queries
          url.gsub!(/\/\d+-\d+(\/|$)/, '/:month/') # Combine all date (year-month) queries
          url.gsub!(/\/\d+[\w-]*/, '/:id') # replace identifiers in URLs request[:url] # TODO: improve me
          url
        
        when :failed
          request[:error]
        else
          raise "Cannot group this request: #{request.inspect}" 
        end
      end
    end
  end

end