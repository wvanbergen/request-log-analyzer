
module RailsAnalyzer
  class Summarizer

    attr_reader :actions
    attr_reader :request_count
    attr_reader :first_request_at
    attr_reader :last_request_at

    attr_accessor :blocker_duration
    DEFAULT_BLOCKER_DURATION = 1.0
   
    def initialize
      @actions  = {}
      @blockers = {}
      @request_count = 0
      @blocker_duration = DEFAULT_BLOCKER_DURATION
      @calculate_database = $*.include?('-c') || $*.include?('--calculate-database')
    end
   
    def group(request, &block)
      @request_count += 1
      @first_request_at ||= request[:timestamp] # assume time-based order
      @last_request_at  = request[:timestamp]   # assume time-based order
      
      hash = block_given? ? yield(request) : request.hash

      @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                            :min_time => request[:duration], :max_time => request[:duration]  }
                            
      @actions[hash][:count] += 1
      @actions[hash][:total_time] += request[:duration]
      @actions[hash][:total_db_time] += request[:db] if request[:db]
      @actions[hash][:total_db_time] += request[:duration] - request[:rendering] if @calculate_database

      @actions[hash][:total_rendering_time] += request[:rendering] if request[:rendering]
      
      @actions[hash][:min_time] = [@actions[hash][:min_time], request[:duration]].min
      @actions[hash][:max_time] = [@actions[hash][:min_time], request[:duration]].max
      @actions[hash][:mean_time] = @actions[hash][:total_time] / @actions[hash][:count].to_f
      
      @actions[hash][:mean_db_time] = @actions[hash][:total_db_time] / @actions[hash][:count].to_f      
      @actions[hash][:mean_rendering_time] = @actions[hash][:total_rendering_time] / @actions[hash][:count].to_f            
      
      if request[:duration] > @blocker_duration
        @blockers[hash] ||= { :count => 0, :total_time => 0.0 }
        @blockers[hash][:count]      += 1
        @blockers[hash][:total_time] += request[:duration]
      end
      
    end
    
    def sort_actions_by(field, min_count = nil)
      actions = min_count.nil? ? @actions.to_a : @actions.delete_if { |k, v| v[:count] < min_count}.to_a
      actions.sort { |a, b| (a[1][field.to_sym] <=> b[1][field.to_sym]) }
    end

    def sort_blockers_by(field, min_count = nil)
      blockers = min_count.nil? ? @blockers.to_a : @blockers.delete_if { |k, v| v[:count] < min_count}.to_a
      blockers.sort { |a, b| a[1][field.to_sym] <=> b[1][field.to_sym] } 
    end

    
    def duration
      (@last_request_at - @first_request_at).round
    end
    

  end
end 
