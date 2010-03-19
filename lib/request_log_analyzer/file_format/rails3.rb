module RequestLogAnalyzer::FileFormat

  # Default FileFormat class for Rails 3 logs.
  #
  # For now, this is just a basic implementation. It will probaby change after 
  # Rails 3 final has been released.
  class Rails3 < Base

    extend CommonRegularExpressions

    # Started GET "/queries" for 127.0.0.1 at 2010-02-25 16:15:18
    line_definition :started do |line|
      line.header = true
      line.teaser = /Started /
      line.regexp = /Started ([A-Z]+) "([^"]+)" for (#{ip_address}) at (#{timestamp('%Y-%m-%d %H:%M:%S')})/
      
      line.capture(:method)
      line.capture(:path)
      line.capture(:ip)
      line.capture(:timestamp).as(:timestamp)
    end
    
    # Processing by QueriesController#index as HTML
    line_definition :processing do |line|
      line.teaser = /Processing by /
      line.regexp = /Processing by (\w+)\#(\w+) as (\w+)/
      
      line.capture(:controller)
      line.capture(:action)
      line.capture(:format)
    end
    
    # Completed in 9ms (Views: 4.9ms | ActiveRecord: 0.5ms) with 200
    line_definition :completed do |line|
      line.footer = true
      line.teaser = /Completed /
      line.regexp = /Completed (\d+) .* in (\d+)ms \([^\)]*\)/

      line.capture(:status).as(:integer)
      line.capture(:duration).as(:duration, :unit => :msec)
    end
    
    # ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/willem/Code/warehouse/app/views/queries/execute.csv.erb:
    line_definition :failure do |line|
      line.footer = true
      line.regexp = /((?:[A-Z]\w*[a-z]\w+\:\:)*[A-Z]\w*[a-z]\w+) \((.*)\)(?: on line #(\d+) of (.+))?\:\s*$/

      line.capture(:error)
      line.capture(:message)
      line.capture(:line).as(:integer)
      line.capture(:file)
    end
    
    # # Not parsed at the moment:
    #  SQL (0.2ms)  SET SQL_AUTO_IS_NULL=0
    #  Query Load (0.4ms)  SELECT `queries`.* FROM `queries`
    # Rendered collection (0.0ms)
    # Rendered queries/index.html.erb (0.6ms)
    
    REQUEST_CATEGORIZER = lambda { |request| "#{request[:controller]}##{request[:action]}.#{request[:format]}" }
    
    report do |analyze|
      
      analyze.timespan
      analyze.hourly_spread
      
      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Most requested'
      analyze.frequency :method, :title => 'HTTP methods'
      analyze.frequency :status, :title => 'HTTP statuses returned'
      
      analyze.duration :duration, :category => REQUEST_CATEGORIZER, :title => "Request duration",    :line_type => :completed
      # analyze.duration :view,     :category => REQUEST_CATEGORIZER, :title => "View rendering time", :line_type => :completed
      # analyze.duration :db,       :category => REQUEST_CATEGORIZER, :title => "Database time",       :line_type => :completed
      
      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Process blockers (> 1 sec duration)',
        :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }
    end
    
    class Request < RequestLogAnalyzer::Request
      def convert_timestamp(value, defintion)
        value.gsub(/[^0-9]/, '')[0...14].to_i
      end
    end

  end
end