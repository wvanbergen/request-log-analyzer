module RequestLogAnalyzer
  
  # The RequestLogAnalyzer::Controller class creates a LogParser instance for the
  # requested file format, and connect it with sources and aggregators.
  #
  # Sources are streams or files from which the requests will be parsed.
  # Aggregators will handle every passed request to yield a meaningfull results.
  #
  # - Use the build-function to build a controller instance using command line arguments.
  # - Use add_aggregator to register a new aggregator
  # - Use add_source to register a new aggregator
  # - Use the run! method to start the parser and send the requests to the aggregators.
  #
  # Note that the order of sources can be imported if you have log files than succeed
  # eachother. Requests that span over succeeding files will be parsed correctly if the
  # sources are registered in the correct order. This can be helpful to parse requests
  # from several logrotated log files.
  class Controller

    include RequestLogAnalyzer::FileFormat::Awareness
    
    attr_reader :aggregators
    attr_reader :filters
    attr_reader :log_parser
    attr_reader :source
    attr_reader :output
    attr_reader :options

    # Builds a RequestLogAnalyzer::Controller given parsed command line arguments
    # <tt>arguments<tt> A CommandLine::Arguments hash containing parsed commandline parameters.
    # <rr>report_with</tt> Width of the report. Defaults to 80.
    def self.build(arguments)
      options = { }

      options[:database] = arguments[:database] if arguments[:database]
      options[:debug]    = arguments[:debug]
      options[:dump]     = arguments[:dump]

      output_class = RequestLogAnalyzer::Output::const_get(arguments[:output])
      if arguments[:file]
        output_file = File.new(arguments[:file], "w+")
        options[:output] = output_class.new(output_file, :width => 80, :color => false, :characters => :ascii)
      else
        options[:output] = output_class.new(STDOUT, :width => arguments[:report_width].to_i, 
            :color => !arguments[:boring], :characters => (arguments[:boring] ? :ascii : :utf))
      end
                
      # Create the controller with the correct file format
      file_format = RequestLogAnalyzer::FileFormat.load(arguments[:format])

      # register sources
      if arguments.parameters.length == 1
        file = arguments.parameters[0]
        if file == '-' || file == 'STDIN'
          options.store(:source_files, $stdin)
        elsif File.exist?(file)
          options.store(:source_files, file)
        else
          puts "File not found: #{file}"
          exit(0)
        end
      else
        options.store(:source_files, arguments.parameters)
      end
      
      controller = Controller.new(RequestLogAnalyzer::Source::LogParser.new(file_format, options), options)
      #controller = Controller.new(RequestLogAnalyzer::Source::Database.new(file_format, options), options)

      options[:parse_strategy] = arguments[:parse_strategy]
      
      # register filters        
      if arguments[:after] || arguments[:before]
        filter_options = {}
        filter_options[:after]  = DateTime.parse(arguments[:after])  
        filter_options[:before] = DateTime.parse(arguments[:before]) if arguments[:before]
        controller.add_filter(:timespan, filter_options)
      end
      
      arguments[:reject].each do |(field, value)|
        controller.add_filter(:field, :mode => :reject, :field => field, :value => value)
      end
      
      arguments[:select].each do |(field, value)|
        controller.add_filter(:field, :mode => :select, :field => field, :value => value)
      end

      # register aggregators
      arguments[:aggregator].each { |agg| controller.add_aggregator(agg.to_sym) }

      # register the database 
      controller.add_aggregator(:database)   if arguments[:database] && !arguments[:aggregator].include?('database')
      controller.add_aggregator(:summarizer) if arguments[:aggregator].empty?
    
      # register the echo aggregator in debug mode
      controller.add_aggregator(:echo) if arguments[:debug]
      
      file_format.setup_environment(controller)
          
      return controller
    end

    # Builds a new Controller for the given log file format.
    # <tt>format</tt> Logfile format. Defaults to :rails
    # Options are passd on to the LogParser.
    # * <tt>:aggregator</tt> Aggregator array.
    # * <tt>:database</tt> Database the controller should use.
    # * <tt>:echo</tt> Output debug information.
    # * <tt>:silent</tt> Do not output any warnings.
    # * <tt>:colorize</tt> Colorize output
    # * <tt>:output</tt> All report outputs get << through this output.
    def initialize(source, options = {})

      @source      = source
      @options     = options
      @aggregators = []
      @filters     = []
      @output      = options[:output]
      
      # Requester format through RequestLogAnalyzer::FileFormat and construct the parser
      register_file_format(@source.file_format) 
      
      # Pass all warnings to every aggregator so they can do something useful with them.
      @source.warning = lambda { |type, message, lineno|  @aggregators.each { |agg| agg.warning(type, message, lineno) } } if @source

      # Handle progress messagess
      @source.progress = lambda { |message, value| handle_progress(message, value) } if @source
    end
    
    # Progress function.
    # Expects :started with file, :progress with current line and :finished or :interrupted when done.
    # <tt>message</tt> Current state (:started, :finished, :interupted or :progress).
    # <tt>value</tt> File or current line.
    def handle_progress(message, value = nil)
      case message
      when :started
        @progress_bar = CommandLine::ProgressBar.new(File.basename(value), File.size(value), STDOUT)
      when :finished
        @progress_bar.finish
        @progress_bar = nil
      when :interrupted
        if @progress_bar
          @progress_bar.halt
          @progress_bar = nil
        end
      when :progress
        @progress_bar.set(value)
      end
    end
    
    # Adds an aggregator to the controller. The aggregator will be called for every request 
    # that is parsed from the provided sources (see add_source)
    def add_aggregator(agg)      
      agg = RequestLogAnalyzer::Aggregator.const_get(RequestLogAnalyzer::to_camelcase(agg)) if agg.kind_of?(Symbol)
      @aggregators << agg.new(@source, @options)
    end
    
    alias :>> :add_aggregator
    
    # Adds a request filter to the controller.
    def add_filter(filter, filter_options = {})
      filter = RequestLogAnalyzer::Filter.const_get(RequestLogAnalyzer::to_camelcase(filter)) if filter.kind_of?(Symbol)
      @filters << filter.new(file_format, @options.merge(filter_options))
    end
    
    # Push a request through the entire filterchain (@filters).
    # <tt>request</tt> The request to filter.
    # Returns the filtered request or nil.
    def filter_request(request)
      @filters.each do |filter| 
        request = filter.filter(request)
        return nil if request.nil?
      end
      return request
    end
    
    # Push a request to all the aggregators (@aggregators).
    # <tt>request</tt> The request to push to the aggregators.    
    def aggregate_request(request)
      return unless request
      @aggregators.each { |agg| agg.aggregate(request) }
    end
    
    # Runs RequestLogAnalyzer
    # 1. Call prepare on every aggregator
    # 2. Generate requests from source object
    # 3. Filter out unwanted requests
    # 4. Call aggregate for remaning requests on every aggregator
    # 4. Call finalize on every aggregator
    # 5. Call report on every aggregator
    # 6. Finalize Source
    def run!
      
      @aggregators.each { |agg| agg.prepare }
      install_signal_handlers
      
      @source.each_request do |request|
        aggregate_request(filter_request(request))
        break if @interrupted
      end

      @aggregators.each { |agg| agg.finalize }

      @output.header
      @aggregators.each { |agg| agg.report(@output) }
      @output.footer
            
      @source.finalize
      
      if @output.io.kind_of?(File)
        puts
        puts "Report written to: " + File.expand_path(@output.io.path)
        puts "Need an expert to analyze your application?"
        puts "Mail to contact@railsdoctors.com or visit us at http://railsdoctors.com"
        puts "Thanks for using request-log-analyzer!"
        @output.io.close
      end
    end
    
    def install_signal_handlers
      Signal.trap("INT") do
        handle_progress(:interrupted)
        puts "Caught interrupt! Stopping parsing..."
        @interrupted = true
      end
    end
    
  end
end
