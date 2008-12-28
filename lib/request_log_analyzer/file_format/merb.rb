module RequestLogAnalyzer::FileFormat::Merb

  LINE_DEFINITIONS = {
    
    # ~ Started request handling: Fri Aug 29 11:10:23 +0200 2008
    :started => {
      :header   => true,
      :teaser   => /Started/,
      :regexp   => /Started request handling\:\ (.+)/,
      :captures => [{ :name => :timestamp, :type => :timestamp, :anonymize => :slightly }]
    },
    
    # ~ Params: {"action"=>"create", "controller"=>"session"}
    # ~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"d}
    :params => {
      :teaser   => /Params/,
      :regexp   => /Params\:\ \{(.+)\}/,
      :captures => [{ :name => :raw_hash, :type => :string}]
    },
    
    # ~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}
    :completed => {
      :footer   => true,
      :teaser   => /\{:dispatch_time/,
      :regexp   => /\{\:dispatch_time=>(\d+\.\d+(?:e-?\d+)?), (?:\:after_filters_time=>(\d+\.\d+(?:e-?\d+)?), )?(?:\:before_filters_time=>(\d+\.\d+(?:e-?\d+)?), )?\:action_time=>(\d+\.\d+(?:e-?\d+)?)\}/,
      :captures => [{ :name => :dispatch_time,       :type => :sec, :anonymize => :slightly }, 
                    { :name => :after_filters_time,  :type => :sec, :anonymize => :slightly }, 
                    { :name => :before_filters_time, :type => :sec, :anonymize => :slightly }, 
                    { :name => :action_time,         :type => :sec, :anonymize => :slightly }]
    }
  }
    
end
