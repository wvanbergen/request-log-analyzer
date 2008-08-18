module RailsAnalyzer
  
  # Functions to summarize an array of requets.
  # Can calculate request counts, duratations, mean times etc. of all the requests given.
  class Summarizer

    attr_reader :actions
    attr_reader :request_count
    attr_reader :request_time_graph
    attr_reader :first_request_at
    attr_reader :last_request_at

    attr_accessor :blocker_duration
    DEFAULT_BLOCKER_DURATION = 1.0
   
    # Initializer. Sets global variables
    # Options
    # * <tt>:calculate_database</tt> Calculate the database times if they are not explicitly logged.
    def initialize(options = {})
      @actions  = {}
      @blockers = {}
      @request_count = 0
      @blocker_duration = DEFAULT_BLOCKER_DURATION
      @calculate_database = options[:calculate_database]
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    end
   
    # Check if any of the request parsed had a timestamp.
    def has_timestamps?
      @first_request_at
    end
   
    # Parse a request string into a hash containing all keys found in the string.
    # Yields the hash found to the block operator.
    # <tt>request</tt> The request string to parse.
    # <tt>&block</tt> Block operator
    def group(request, &block)
      request[:duration] ||= 0
      
      case request[:type]   
        when :started      
          @first_request_at ||= request[:timestamp] # assume time-based order of file
          @last_request_at  = request[:timestamp]   # assume time-based order of file
          @request_time_graph[request[:timestamp][11..12].to_i] +=1

        when :completed
          @request_count += 1 
          hash = block_given? ? yield(request) : request.hash

          @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                                :min_time => request[:duration], :max_time => request[:duration] }
                            
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

        when :failure
          puts 'fail!'
      end
    end
    
    # Return a list of requests sorted on a specific action field
    # <tt>field</tt> The action field to sort by.
    # <tt>min_count</tt> Values which fall below this amount are not returned (default nil).
    def sort_actions_by(field, min_count = nil)
      actions = min_count.nil? ? @actions.to_a : @actions.delete_if { |k, v| v[:count] < min_count}.to_a
      actions.sort { |a, b| (a[1][field.to_sym] <=> b[1][field.to_sym]) }
    end

    # Returns a list of request blockers sorted by a specific field
    # <tt>field</tt> The action field to sort by.
    # <tt>min_count</tt> Values which fall below this amount are not returned (default @blocker_duration).
    def sort_blockers_by(field, min_count = @blocker_duration)
      blockers = min_count.nil? ? @blockers.to_a : @blockers.delete_if { |k, v| v[:count] < min_count}.to_a
      blockers.sort { |a, b| a[1][field.to_sym] <=> b[1][field.to_sym] } 
    end

    # Calculate the duration of a request
    # Returns a DateTime object if possible, 0 otherwise.
    def duration
      (@last_request_at && @first_request_at) ? (DateTime.parse(@last_request_at) - DateTime.parse(@first_request_at)).round : 0
    end
    
    # Check if the request time graph usable data.
    def request_time_graph?
      @request_time_graph.uniq != [0] && duration > 0
    end

  end
end 
