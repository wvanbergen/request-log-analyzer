module RequestLogAnalyzer::Tracker

  # Base Tracker class. All other trackers inherit from this class
  #
  # Accepts the following options:
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:output</tt> Direct output here (defaults to STDOUT)
  # * <tt>:unless</tt> Proc that has to return nil for a request to be passed to the tracker.
  #
  # For example :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }
  class Base

    attr_reader :options

    # Initialize the class
    # Note that the options are only applicable if should_update? is not overwritten
    # by the inheriting class.
    #
    # === Options
    # * <tt>:if</tt> Handle request if this proc is true for the handled request.
    # * <tt>:unless</tt> Handle request if this proc is false for the handled request.
    # * <tt>:line_type</tt> Line type this tracker will accept.
    def initialize(options ={})
      @options = options
      setup_should_update_checks!
    end

    # Sets up the tracker's should_update? checks.
    def setup_should_update_checks!
      @should_update_checks = []
      @should_update_checks.push( lambda { |request| request.has_line_type?(options[:line_type]) } ) if options[:line_type]
      @should_update_checks.push(options[:if]) if options[:if].respond_to?(:call)
      @should_update_checks.push( lambda { |request| request[options[:if]] }) if options[:if].kind_of?(Symbol)
      @should_update_checks.push( lambda { |request| !options[:unless].call(request) }) if options[:unless].respond_to?(:call)
      @should_update_checks.push( lambda { |request| !request[options[:unless]] }) if options[:unless].kind_of?(Symbol)
    end
    
    # Creates a lambda expression to return a static field from a request. If the 
    # argument already is a lambda exprssion, it will simply return the argument.
    def create_lambda(arg)
      case arg
      when Proc   then arg
      when Symbol then lambda { |request| request[arg] }
      else raise "Canot create a lambda expression from this argument: #{arg.inspect}!"
      end
    end

    # Hook things that need to be done before running here.
    def prepare
    end

    # Will be called with each request.
    # <tt>request</tt> The request to track data in.
    def update(request)
    end

    # Hook things that need to be done after running here.
    def finalize
    end

    # Determine if we should run the update function at all.
    # Usually the update function will be heavy, so a light check is done here
    # determining if we need to call update at all.
    #
    # Default this checks if defined:
    #  * :line_type is also in the request hash.
    #  * :if is true for this request.
    #  * :unless if false for this request
    #
    # <tt>request</tt> The request object.
    def should_update?(request)
      @should_update_checks.all? { |c| c.call(request) }
    end

    # Hook report generation here.
    # Defaults to self.inspect
    # <tt>output</tt> The output object the report will be passed to.
    def report(output)
      output << self.inspect
      output << "\n"
    end

    # The title of this tracker. Used for reporting.
    def title
      self.class.to_s
    end

    # This method is called by RequestLogAnalyzer::Aggregator:Summarizer to retrieve an
    # object with all the results of this tracker, that can be dumped to YAML format.
    def to_yaml_object
      nil
    end
  end
end

require 'request_log_analyzer/tracker/numeric_value'
require 'request_log_analyzer/tracker/duration'
require 'request_log_analyzer/tracker/frequency'
require 'request_log_analyzer/tracker/hourly_spread'
require 'request_log_analyzer/tracker/timespan'
require 'request_log_analyzer/tracker/traffic'
