require 'date'
module MerbAnalyzer
  
  # Functions to summarize an array of requets.
  # Can calculate request counts, duratations, mean times etc. of all the requests given.
  class Summarizer < Base::Summarizer

    # Initializer. Sets global variables
    def initialize_hook(options = {})
      @hash_cache = nil
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
          
        when :params
          params_hash = {}
          request[:raw_hash].split(',').collect{|x| x.split('=>')}.each do |k,v|
            key = k.gsub('"', '').gsub(' ', '').to_sym
            value = v.gsub('"', '')
            request.store(key, value)
          end
          
          hash = block_given? ? yield(request) : request.hash

          @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                                 :min_time => request[:duration], :max_time => request[:duration] }

          @actions[hash][:count] += 1
          request[:method] = 'GET' unless request[:method]
          @methods[request[:method].upcase.to_sym] += 1

          @hash_cache = hash
        when :completed
          @request_count += 1 
          
          @actions[@hash_cache][:total_time] += request[:dispatch_time]
          @actions[@hash_cache][:mean_time] = @actions[@hash_cache][:total_time] / @actions[@hash_cache][:count].to_f          
          @actions[@hash_cache][:min_time] = [@actions[@hash_cache][:min_time], request[:dispatch_time]].min
          @actions[@hash_cache][:max_time] = [@actions[@hash_cache][:min_time], request[:dispatch_time]].max
          
          @actions[@hash_cache][:total_db_time] = 0
          @actions[@hash_cache][:mean_db_time] = 0
          @actions[@hash_cache][:mean_rendering_time] = 0
          
        when :failed

      end
    end
  end
end 
