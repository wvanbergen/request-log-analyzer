module Base
  
  # Functions to summarize an array of requets.
  # Can calculate request counts, duratations, mean times etc. of all the requests given.
  class Summarizer
    attr_reader :actions
    attr_reader :errors
    attr_reader :request_count
    attr_reader :request_time_graph
    attr_reader :first_request_at
    attr_reader :last_request_at
    attr_reader :methods

    attr_accessor :blocker_duration
    DEFAULT_BLOCKER_DURATION = 1.0
   
    # Initializer. Sets global variables
    # Options
    # * <tt>:calculate_database</tt> Calculate the database times if they are not explicitly logged.
    def initialize(options = {})
      @actions  = {}
      @blockers = {}
      @errors   = {}
      @request_count = 0
      @blocker_duration = DEFAULT_BLOCKER_DURATION
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      @methods = {:GET => 0, :POST => 0, :PUT => 0, :DELETE => 0}
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
      raise 'No group function defined for this type of logfile!'
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
