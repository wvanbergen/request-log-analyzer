module MerbAnalyzer

  class LogParser < Base::LogParser
    LOG_LINES = {
      # ~ Started request handling: Fri Aug 29 11:10:23 +0200 2008
      :started => {
        :teaser => /Started/,
        :regexp => /Started request handling\:\ (.+)/,
        :params => {:timestamp => 1}
      },
      # ~ Params: {"action"=>"create", "controller"=>"session"}
      # ~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"d}
      :params => {
        :teaser => /Params/,
        :regexp => /Params\:\ \{(.+)\}/,
        :params => { :raw_hash => 1 }
      },
      # ~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}
      :completed => {
        :teaser => /\{:dispatch_time/,
        :regexp => /\{\:dispatch_time=>(.+), \:after_filters_time=>(.+), \:before_filters_time=>(.+), \:action_time=>(.+)\}/,
        :params => { :dispatch_time => [1, :to_f], :after_filters_time => [2, :to_f], :before_filters_time => [3, :to_f], :action_time => [4, :to_f] }
      }
    }
  end
end
