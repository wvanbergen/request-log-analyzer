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
    def self.build(arguments, report_width = 80)
            
      options = { :report_width => arguments[:report_width].to_i, :output => STDOUT}

      options[:database] = arguments[:database] if arguments[:database]
      options[:debug]    = arguments[:debug]
      options[:colorize] = !arguments[:boring]

      if arguments[:file]
        options[:output] = File.new(arguments[:file], "w+")
        options[:colorize] = false
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
      
      controller = Controller.new(RequestLogAnalyzer::Source::LogFile.new(file_format, options), options)

      options[:assume_correct_order] = arguments[:assume_correct_order]
      
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
        @progress_bar = ProgressBar.new(green(File.basename(value), options[:colorize]), File.size(value))
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
      if agg.kind_of?(Symbol)
        require File.dirname(__FILE__) + "/aggregator/#{agg}"
        agg = RequestLogAnalyzer::Aggregator.const_get(agg.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join(''))
      end
      
      @aggregators << agg.new(@source, @options)
    end
    
    alias :>> :add_aggregator
    
    # Adds a request filter to the controller.
    def add_filter(filter, filter_options = {})
      if filter.kind_of?(Symbol)
        require File.dirname(__FILE__) + "/filter/#{filter}"
        filter = RequestLogAnalyzer::Filter.const_get(filter.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join(''))
      end
      
      @filters << filter.new(file_format, @options.merge(filter_options))
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
      
      @filters.each { |filter| filter.prepare }
      @aggregators.each { |agg| agg.prepare }
      
      begin
        @source.requests do |request|
          @filters.each { |filter| request = filter.filter(request) }
          @aggregators.each { |agg| agg.aggregate(request) } if request
        end
      rescue Interrupt => e
        handle_progress(:interrupted)
        puts "Caught interrupt! Stopped parsing."
      end

      puts "\n"
      
      @aggregators.each { |agg| agg.finalize }
      @aggregators.each { |agg| agg.report(@output, options[:report_width], options[:colorize]) }
      
      @source.finalize
    end
    
  end
end
