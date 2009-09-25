module RequestLogAnalyzer::Tracker

  # const_missing: this function is used to load subclasses in the RequestLogAnalyzer::Track namespace.
  # It will automatically load the required file based on the class name
  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end

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
  
  module StatisticsTracking
    
    # Update sthe running calculation of statistics with the newly found numeric value.
    # <tt>category</tt>:: The category for which to update the running statistics calculations
    # <tt>number</tt>:: The numeric value to update the calculations with.
    def update_statistics(category, number)
      @categories[category] ||= {:hits => 0, :sum => 0, :mean => 0.0, :sum_of_squares => 0.0, :min => number, :max => number }
      delta = number - @categories[category][:mean]

      @categories[category][:hits]           += 1
      @categories[category][:mean]           += (delta / @categories[category][:hits])
      @categories[category][:sum_of_squares] += delta * (number - @categories[category][:mean])
      @categories[category][:sum]            += number
      @categories[category][:min]             = number if number < @categories[category][:min]
      @categories[category][:max]             = number if number > @categories[category][:max]
    end
    
    # Get the number of hits of a specific category.
    # <tt>cat</tt> The category
    def hits(cat)
      @categories[cat][:hits]
    end

    # Get the total duration of a specific category.
    # <tt>cat</tt> The category
    def sum(cat)
      @categories[cat][:sum]
    end

    # Get the minimal duration of a specific category.
    # <tt>cat</tt> The category
    def min(cat)
      @categories[cat][:min]
    end

    # Get the maximum duration of a specific category.
    # <tt>cat</tt> The category
    def max(cat)
      @categories[cat][:max]
    end

    # Get the average duration of a specific category.
    # <tt>cat</tt> The category
    def mean(cat)
      @categories[cat][:mean]
    end

    # Get the standard deviation of the duration of a specific category.
    # <tt>cat</tt> The category
    def stddev(cat)
      Math.sqrt(variance(cat))
    end

    # Get the variance of the duration of a specific category.
    # <tt>cat</tt> The category
    def variance(cat)
      return 0.0 if @categories[cat][:hits] <= 1
      (@categories[cat][:sum_of_squares] / (@categories[cat][:hits] - 1))
    end

    # Get the average duration of a all categories.
    def mean_overall
      sum_overall / hits_overall
    end

    # Get the cumlative duration of a all categories.
    def sum_overall
      @categories.inject(0.0) { |sum, (name, cat)| sum + cat[:sum] }
    end

    # Get the total hits of a all categories.
    def hits_overall
      @categories.inject(0) { |sum, (name, cat)| sum + cat[:hits] }
    end
    
    # Return categories sorted by a given key.
    # <tt>by</tt> The key to sort on. This parameter can be omitted if a sorting block is provided instead
    def sorted_by(by = nil)
      if block_given?
        categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }
      else
        categories.sort { |a, b| send(by, b[0]) <=> send(by, a[0]) }
      end
    end
    
    # Returns the column header for a statistics table to report on the statistics result
    def statistics_header(options)
      [
        {:title => options[:title], :width => :rest},
        {:title => 'Hits',   :align => :right, :highlight => (options[:highlight] == :hits),   :min_width => 4},
        {:title => 'Sum',    :align => :right, :highlight => (options[:highlight] == :sum),    :min_width => 6},
        {:title => 'Mean',   :align => :right, :highlight => (options[:highlight] == :mean),   :min_width => 6},
        {:title => 'StdDev', :align => :right, :highlight => (options[:highlight] == :stddev), :min_width => 6},
        {:title => 'Min',    :align => :right, :highlight => (options[:highlight] == :min),    :min_width => 6},
        {:title => 'Max',    :align => :right, :highlight => (options[:highlight] == :max),    :min_width => 6}
      ]
    end
    
    # Returns a row of statistics information for a report table, given a category
    def statistics_row(cat)
      [cat, hits(cat), display_value(sum(cat)), display_value(mean(cat)), display_value(stddev(cat)),
                display_value(min(cat)), display_value(max(cat))]
    end
  end
end