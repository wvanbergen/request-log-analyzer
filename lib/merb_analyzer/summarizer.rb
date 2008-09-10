require 'date'
module MerbAnalyzer
  
  # Functions to summarize an array of requets.
  # Can calculate request counts, duratations, mean times etc. of all the requests given.
  class Summarizer < Base::Summarizer

    # Initializer. Sets global variables
    # Options
    # * <tt>:calculate_database</tt> Calculate the database times if they are not explicitly logged.
    def initialize(options = {})
      @actions  = {}
      @blockers = {}
      @errors   = {}
      @request_count = 0
      @blocker_duration = DEFAULT_BLOCKER_DURATION
      @calculate_database = options[:calculate_database]
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      @methods = {:GET => 0, :POST => 0, :PUT => 0, :DELETE => 0}
    end

    # Parse a request string into a hash containing all keys found in the string.
    # Yields the hash found to the block operator.
    # <tt>request</tt> The request string to parse.
    # <tt>&block</tt> Block operator
    def group(request, &block)
      request[:duration] ||= 0
      
      case request[:type]   
        when :started 
          @request_count += 1

          params = {}
          request[:params].split(',').collect{|x| x.gsub!('"', '').split('=>')}.each do |param|
            request.store(param[0], param[1])
          end
          
          hash = block_given? ? yield(request) : request.hash

          @actions[hash] ||= {:count => 0, :total_time => 0.0, :total_db_time => 0.0, :total_rendering_time => 0.0, 
                                :min_time => request[:duration], :max_time => request[:duration] }

          @actions[hash][:count] += 1
          

        when :completed

        when :failed

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

    # Returns a list of request blockers sorted by a specific field
    # <tt>field</tt> The action field to sort by.
    # <tt>min_count</tt> Values which fall below this amount are not returned (default @blocker_duration).
    def sort_errors_by(field, min_count = nil)
      errors = min_count.nil? ? @errors.to_a : @errors.delete_if { |k, v| v[:count] < min_count}.to_a
      errors.sort { |a, b| a[1][field.to_sym] <=> b[1][field.to_sym] } 
    end

  end
end 
