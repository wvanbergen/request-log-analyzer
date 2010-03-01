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
      line.regexp = /Started ([A-Z]+) ("[^"]+") for (#{ip_address}) at (#{timestamp('%y-%m-%d %k:%M:%S')})/
      line.captures << { :name => :method,    :type => :string    } <<
                       { :name => :url,       :type => :string    } <<
                       { :name => :ip,        :type => :string    } <<
                       { :name => :timestamp, :type => :timestamp }
    end
    
    # Processing by QueriesController#index as HTML
    line_definition :processing do |line|
      line.teaser = /Processing by /
      line.regexp = /Processing by (\w+)\#(\w+) as (\w+)/
      line.captures << { :name => :controller, :type => :string } <<
                       { :name => :action,     :type => :string } <<
                       { :name => :format,     :type => :string }
    end
    
    # Completed in 9ms (Views: 4.9ms | ActiveRecord: 0.5ms) with 200
    line_definition :completed do |line|
      line.footer = true
      line.teaser = /Completed in /
      line.regexp = /Completed in (\d+)ms \([^\)]*\) with (\d+)/
      line.captures << { :name => :duration, :type => :duration, :unit => :msec } <<
                       { :name => :status,   :type => :integer }
    end
    
    
    # # Not parsed at the moment:
    #  SQL (0.2ms)  SET SQL_AUTO_IS_NULL=0
    #  Query Load (0.4ms)  SELECT `queries`.* FROM `queries`
    # Rendered collection (0.0ms)
    # Rendered queries/index.html.erb (0.6ms)
    
    

  end
end