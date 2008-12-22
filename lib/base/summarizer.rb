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
    def initialize(options = {})
      @actions  = {}
      @blockers = {}
      @errors   = {}
      @request_count = 0
      @blocker_duration = DEFAULT_BLOCKER_DURATION
      @request_time_graph = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      @methods = {:GET => 0, :POST => 0, :PUT => 0, :DELETE => 0}
      
      self.initialize_hook(options) if self.respond_to?(:initialize_hook)
    end
   
    # Check if any of the request parsed had a timestamp.
    def has_timestamps?
      @first_request_at
    end
   
    # Calculate the duration of a request
    # Returns a DateTime object if possible, 0 otherwise.
    def duration
      (@last_request_at && @first_request_at) ? (DateTime.parse(@last_request_at) - DateTime.parse(@first_request_at)).ceil : 0
    end
    
    # Check if the request time graph usable data.
    def request_time_graph?
      @request_time_graph.uniq != [0] && duration > 0
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
    
    # Compare date strings fast
    # Assumes date formats: "2008-07-14 12:11:20"
    # <tt>first_date</tt> The first date string
    # <tt>second_date</tt> The second date string
    # Returns -1 if first_date < second_date, 0 if equal
    # and 1 if first_date > second_date
    def compare_string_dates first_date, second_date
      first_date = first_date[0..9]
      second_date = second_date[0..9]
      
      first_year = first_date[0..3].to_i
      second_year = second_date[0..3].to_i
      return -1 if first_year < second_year
      return 1 if first_year > second_year

      first_month = first_date[5..6].to_i
      second_month = second_date[5..6].to_i
      return -1 if first_month < second_month
      return 1 if first_month > second_month

      first_day = first_date[8..9].to_i
      second_day = second_date[8..9].to_i
      return -1 if first_day < second_day
      return 1 if first_day > second_day
      
      return 0
    end
  end
end 
