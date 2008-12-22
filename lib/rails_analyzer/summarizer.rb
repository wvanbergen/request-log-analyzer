require 'date'
module RailsAnalyzer
  
  # Functions to summarize an array of requets.
  # Can calculate request counts, duratations, mean times etc. of all the requests given.
  class Summarizer < Base::Summarizer

    # Initializer. Sets global variables
    # Options
    # * <tt>:calculate_database</tt> Calculate the database times if they are not explicitly logged.
    def initialize_hook(options = {})
      @calculate_database = options[:calculate_database]
    end

    # Parse a request string into a hash containing all keys found in the string.
    # Yields the hash found to the block operator.
    # <tt>request</tt> The request string to parse.
    # <tt>&block</tt> Block operator
    def group(request, &block)
      request[:duration] ||= 0
      
      case request[:type]   
        when :started 
          if request[:timestamp]
            if @first_request_at.nil? || compare_string_dates(request[:timestamp], @first_request_at) == -1
              @first_request_at = request[:timestamp]
            end

            if @last_request_at.nil? || compare_string_dates(request[:timestamp], @last_request_at) == 1
              @last_request_at = request[:timestamp]
            end

            @request_time_graph[request[:timestamp][11..12].to_i] +=1
          end
          if request[:method]
            @methods[request[:method].to_sym] ||= 0
            @methods[request[:method].to_sym] += 1
          else
            @methods[:unknown] += 1
          end
        when :completed
          @request_count += 1 
          hash = block_given? ? yield(request) : request.hash

          @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                                :min_time => request[:duration], :max_time => request[:duration] }
                            
          @actions[hash][:count] += 1
          @actions[hash][:total_time] += request[:duration]
          @actions[hash][:total_db_time] += request[:db] if request[:db]
          @actions[hash][:total_db_time] += request[:duration] - request[:rendering] if @calculate_database && request[:duration] && request[:rendering]

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

        when :failed
          hash = request[:error]
          @errors[hash] ||= {:count => 0, :exception_strings => {}}
          @errors[hash][:count] +=1
          
          @errors[hash][:exception_strings][request[:exception_string]] ||= 0
          @errors[hash][:exception_strings][request[:exception_string]] += 1
      end
    end
    
  end
end 
