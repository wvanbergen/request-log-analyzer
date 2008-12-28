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
      :captures => [{:controller => :string}, {:action => :string}, {:format => :string}, {:ip => :string}, {:timestamp => :timestamp}, {:method => :string}]
    },

    # Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a998a2ff0 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a998af660@/home/floorplanner/beta/releases/20081224113708/app/controllers/page_controller.rb:14>}>] rendered_or_redirected.
    # Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.
    :cache_hit => {
      :regexp   => /Filter chain halted as \[\#<ActionController::Caching::Actions::ActionCacheFilter:.+>\] rendered_or_redirected/,
      :captures => []
    },
    
    # RuntimeError (Cannot destroy employee):  /app/models/employee.rb:198:in `before_destroy' 
    :failed => {
      :footer => true,   
      :teaser => /Error/,
      :regexp => /(\w+)(?:Error|Invalid) \((.*)\)\:(.*)/,
      :captures => [{:error => :string}, {:exception_string => :string}, {:stack_trace => :string}]
    },

    # Completed lines: see above
    :completed => {
      :footer   => true,
      :teaser   => /Completed in /,
      :regexp   => Regexp.new("(?:#{RAILS_21_COMPLETED}|#{RAILS_22_COMPLETED})"),
      :captures => [{:duration => :sec},  {:view => :sec},  {:db => :sec},  {:status => :integer}, {:url => :string},  # 2.1 variant 
                    {:duration => :msec}, {:view => :msec}, {:db => :msec}, {:status => :integer}, {:url => :string}]  # 2.2 variant 

    }
  }   
  
  module Summarizer
    
    def setup
      track(:category, :category => :method, :title => 'HTTP methods')
      track(:category, :category => :status, :title => 'HTTP statuses returned')
      track(:category, :category => lambda { |request| request =~ :cache_hit ? 'Cache hit' : 'No hit' }, :title => 'Rails action cache hits')      
    end
    
    def bucket_for(request)
      if options[:combined_requests]
      
        if request =~ :failed
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

          url.gsub!(/\/\d+-\d+-\d+(\/|$)/, '/:date') # Combine all (year-month-day) queries
          url.gsub!(/\/\d+-\d+(\/|$)/, '/:month') # Combine all date (year-month) queries
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