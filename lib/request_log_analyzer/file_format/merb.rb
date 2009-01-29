module RequestLogAnalyzer::FileFormat
  
  class Merb < Base

    # ~ Started request handling: Fri Aug 29 11:10:23 +0200 2008
    line_definition :started do |line|
      line.header = true
      line.teaser = /Started/
      line.regexp = /Started request handling\:\ (.+)/
      line.captures << { :name => :timestamp, :type => :timestamp }
    end    
    
    # ~ Params: {"action"=>"create", "controller"=>"session"}
    # ~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"d}
    line_definition :params do |line|
      line.teaser = /Params/
      line.regexp = /Params\:\ (\{.+\})/
      line.captures << { :name => :params, :type => :eval, :provides => { 
            :namespace => :string, :controller => :string, :action => :string, :format => :string } }
    end

    # ~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}
    line_definition :completed do |line|
      line.footer = true
      line.teaser = /\{:dispatch_time/
      line.regexp = /\{\:dispatch_time=>(\d+\.\d+(?:e-?\d+)?), (?:\:after_filters_time=>(\d+\.\d+(?:e-?\d+)?), )?(?:\:before_filters_time=>(\d+\.\d+(?:e-?\d+)?), )?\:action_time=>(\d+\.\d+(?:e-?\d+)?)\}/
      line.captures << { :name => :dispatch_time,       :type => :duration } \
                    << { :name => :after_filters_time,  :type => :duration } \
                    << { :name => :before_filters_time, :type => :duration } \
                    << { :name => :action_time,         :type => :duration }
    end
    
    REQUEST_CATEGORIZER = Proc.new do |request| 
      category = "#{request[:controller]}##{request[:action]}"
      category = "#{request[:namespace]}::#{category}" if request[:namespace]
      category = "#{category}.#{request[:format]}"     if request[:format]
      category
    end
    
    report do |analyze|
      analyze.timespan :line_type => :started
      analyze.hourly_spread :line_type => :started
      
      analyze.duration :dispatch_time, :category => REQUEST_CATEGORIZER, :title => 'Request dispatch duration'
      # analyze.duration :action_time, :category => REQUEST_CATEGORIZER, :title => 'Request action duration'
      # analyze.duration :after_filters_time, :category => REQUEST_CATEGORIZER, :title => 'Request after_filter duration'
      # analyze.duration :before_filters_time, :category => REQUEST_CATEGORIZER, :title => 'Request before_filter duration'
    end
        
  end

end