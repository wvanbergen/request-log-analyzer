module MerbAnalyzer

  class LogParser < Base::LogParser
    LOG_LINES = {
      # ~ Started request handling: Fri Aug 29 11:10:23 +0200 2008
      # ~ Params: {"action"=>"create", "controller"=>"session"}
      :started => {
        :teaser => /Params/,
        :regexp => /Params {(\w+)}/,
        :params => { :hash => [1, :to_hash }
      },
      # ~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}
      :completed => {
        :teaser => /\{:dispatch_time/,
        :regexp => /\{:dispatch_time=>(\w+), :after_filters_time=>(\w+), :before_filters_time=>(\w+), :action_time=>(\w+)}/,
        :params => { :dispatch_time => [1, :to_f], :after_filters_time => [2, :to_f], :before_filters_time => [3, :to_f], :action_time => [4, :to_f] }
      }
    }
  end
end



#'"action"=>"create", "controller"=>"session"'.split(',').collect{|x| x.split('=>')}
