class RequestLogAnalyzer::FileFormat::Rails < RequestLogAnalyzer::FileFormat
  
  # Processing EmployeeController#index (for 123.123.123.123 at 2008-07-13 06:00:00) [GET]
  line_definition :processing do |line|
    line.header = true # this line is the first log line for a request 
    line.teaser = /Processing /
    line.regexp = /Processing ((?:\w+::)?\w+)#(\w+)(?: to (\w+))? \(for (\d+\.\d+\.\d+\.\d+) at (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d)\) \[([A-Z]+)\]/
    line.captures << { :name => :controller, :type  => :string } \
                  << { :name => :action,     :type  => :string } \
                  << { :name => :format,     :type  => :string } \
                  << { :name => :ip,         :type  => :string, :anonymize => :ip } \
                  << { :name => :timestamp,  :type  => :timestamp, :anonymize => :slightly } \
                  << { :name => :method,     :type  => :string }
  end

  # Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.    
  line_definition :cache_hit do |line|
    line.regexp = /Filter chain halted as \[\#<ActionController::Caching::Actions::ActionCacheFilter:.+>\] rendered_or_redirected/
  end
  
  # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
  line_definition :failed do |line|
    line.footer = true
    line.regexp = /((?:[A-Z]\w+\:\:)*[A-Z]\w+) \((.*)\)(?: on line #(\d+) of .+)?\:(.*)/
    line.captures << { :name => :error,            :type => :string } \
                  << { :name => :exception_string, :type => :string } \
                  << { :name => :line,             :type => :integer } \
                  << { :name => :file,             :type => :string } \
                  << { :name => :stack_trace,      :type => :string, :anonymize => true }
  end


  # Rails < 2.1 completed line example
  # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
  RAILS_21_COMPLETED = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (?:\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(?:\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/

  # Rails > 2.1 completed line example
  # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]  
  RAILS_22_COMPLETED = /Completed in (\d+)ms \((?:View: (\d+), )?DB: (\d+)\) \| (\d\d\d).+\[(http.+)\]/

  # The completed line uses a kind of hack to ensure that both old style logs and new style logs 
  # are both parsed by the same regular expression. The format in Rails 2.2 was slightly changed,
  # but the line contains exactly the same information.
  line_definition :completed do |line|
    
    line.footer = true
    line.teaser = /Completed in /
    line.regexp = Regexp.new("(?:#{RAILS_21_COMPLETED}|#{RAILS_22_COMPLETED})")
    
    line.captures << { :name => :duration, :type => :sec,    :anonymize => :slightly } \
                  << { :name => :view,     :type => :sec,    :anonymize => :slightly } \
                  << { :name => :db,       :type => :sec,    :anonymize => :slightly } \
                  << { :name => :status,   :type => :integer } \
                  << { :name => :url,      :type => :string, :anonymize => :url } # Old variant 
                  
    line.captures << { :name => :duration, :type => :msec,   :anonymize => :slightly } \
                  << { :name => :view,     :type => :msec,   :anonymize => :slightly } \
                  << { :name => :db,       :type => :msec,   :anonymize => :slightly } \
                  << { :name => :status,   :type => :integer} \
                  << { :name => :url,      :type => :string, :anonymize => :url }  # 2.2 variant 
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
      when :processing   
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

  report do |analyze|
    analyze.timespan :line_type => :processing
    analyze.category :category => REQUEST_CATEGORIZER, :title => 'Top 20 hits', :amount => 20, :line_type => :processing
    analyze.category :method, :title => 'HTTP methods'
    analyze.category :status, :title => 'HTTP statuses returned'
    analyze.category :category => lambda { |request| request =~ :cache_hit ? 'Cache hit' : 'No hit' }, :title => 'Rails action cache hits'
    
    analyze.duration :duration, :category => REQUEST_CATEGORIZER, :title => "Request duration",    :line_type => :completed
    analyze.duration :view,     :category => REQUEST_CATEGORIZER, :title => "Database time",       :line_type => :completed
    analyze.duration :db,       :category => REQUEST_CATEGORIZER, :title => "View rendering time", :line_type => :completed
    
    analyze.category :category => REQUEST_CATEGORIZER, :title => 'Process blockers (> 1 sec duration)', 
            :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }, :amount => 20
            
    analyze.hourly_spread :line_type => :processing
    analyze.category :error, :title => 'Failed requests', :line_type => :failed, :amount => 20
  end



end 