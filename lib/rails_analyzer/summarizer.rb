
module RailsAnalyzer
  class Summarizer

    attr_reader :actions
    attr_reader :methods
    attr_reader :request_count
    attr_reader :first_request_at
    attr_reader :last_request_at
   
    def initialize
      @actions = {}
      @methods = {}
      @request_count = 0
    end
   
    def summarize(request)
      @request_count += 1
      @first_request_at ||= request[:timestamp] # assume time-based order
      @last_request_at  = request[:timestamp]   # assume time-based order
      
      hash = self.request_hash(request)
      @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                            :min_time => request[:duration], :max_time => request[:duration]  }
                            
      @actions[hash][:count] += 1
      @actions[hash][:total_time] += request[:duration]
      @actions[hash][:total_db_time] += request[:db] if request[:db]
      @actions[hash][:total_rendering_time] += request[:rendering] if request[:rendering]
      
      @actions[hash][:min_time] = [@actions[hash][:min_time], request[:duration]].min
      @actions[hash][:max_time] = [@actions[hash][:min_time], request[:duration]].max
      @actions[hash][:mean_time] = @actions[hash][:total_time] / @actions[hash][:count].to_f
    end
    
    def sort_actions_by(field)
      @actions.to_a.sort { |a, b| (a[1][field.to_sym] <=> b[1][field.to_sym]) }
    end
    
    def duration
      (@last_request_at - @first_request_at).round
    end
    
    protected
    
    def request_hash(request)
      if request[:url]
        request[:url].split('?').first
      elsif request[:controller] && request[:action]
        "#{request[:controller]}##{request[:action]}"
      else
        raise 'Cannot hash this request! ' + request.inspect
      end
    end
  end
end 
