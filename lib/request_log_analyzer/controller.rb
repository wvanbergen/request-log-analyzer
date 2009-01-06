module RequestLogAnalyzer
  
  VERSION = '0.4.0'
  
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
    attr_reader :sources
    attr_reader :options

    # Builds a RequestLogAnalyzer::Controller given parsed command line arguments
    # <tt>arguments<tt> A CommandLine::Arguments hash containing parsed commandline parameters.
    # <rr>report_with</tt> Width of the report. Defaults to 80.
    def self.build(arguments, report_width = 80)
            
      options = { :report_width => arguments[:report_width].to_i, :output => STDOUT}

      options[:combined_requests] = !arguments[:single_lines]
      options[:database] = arguments[:database] if arguments[:database]
      options[:debug]    = arguments[:debug]
      options[:colorize] = !arguments[:boring]

      if arguments[:file]
        options[:output] = File.new(arguments[:file], "w+")
        options[:colorize] = false
      end
                
      # Create the controller with the correct file format
      file_format = RequestLogAnalyzer::FileFormat.load(arguments[:format])
      controller = Controller.new(file_format, options)

      # register sources
      arguments.parameters.each do |file|
        if file == '-' || file == 'STDIN'
          controller.add_source($stdin)
        elsif File.exist?(file)
          controller.add_source(file) 
        else
          puts "File not found: #{file}"
          exit(0)
        end
      end
      
      # register filters
      # filters are only supported in combined requests mode
      if options[:combined_requests]
        
        options[:assume_correct_order] = arguments[:assume_correct_order]
        
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
        
      end

      # register aggregators
      arguments[:aggregator].each { |agg| controller.add_aggregator(agg.to_sym) }

      # register the database 
      controller.add_aggregator(:database)   if arguments[:database] && !arguments[:aggregator].include?('database')
      controller.add_aggregator(:summarizer) if arguments[:aggregator].empty?
    
      # register the echo aggregator in debug mode
      controller.add_aggregator(:echo) if arguments[:debug]
            
      return controller
    end

    # Builds a new Controller for the given log file format.
    # <tt>format</tt> Logfile format. Defaults to :rails
    # Options are passd on to the LogParser.
    # * <tt>:aggregator</tt> Aggregator array.
    # * <tt>:combined_requests</tt> Combine multiline requests into a single request.
    # * <tt>:database</tt> Database the controller should use.
    # * <tt>:echo</tt> Output debug information.
    # * <tt>:silent</tt> Do not output any warnings.
    # * <tt>:colorize</tt> Colorize output
    # * <tt>:output</tt> All report outputs get << through this output.
    def initialize(format = :rails, options = {})

      @options = options
      @aggregators = []
      @sources     = []
      @filters     = []
      
      # Requester format through RequestLogAnalyzer::FileFormat and construct the parser
      register_file_format(format) 
      @log_parser  = RequestLogAnalyzer::LogParser.new(file_format, @options)
      
      # Pass all warnings to every aggregator so they can do something useful with them.
      @log_parser.warning = lambda { |type, message, lineno|  @aggregators.each { |agg| agg.warning(type, message, lineno) } }

      # Handle progress messagess
      @log_parser.progress = lambda { |message, value| handle_progress(message, value) } 
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
      
      @aggregators << agg.new(@log_parser, @options)
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
    
    # Adds an input source to the controller, which will be scanned by the LogParser. 
    #
    # The sources are scanned in the order they are given to the controller. This can be
    # important if the different sources succeed eachother, for instance logrotated log 
    # files. Make sure they are provided in the correct order.
    def add_source(source)
      @sources << source
    end
    
    alias :<< :add_source
    
    # Runs RequestLogAnalyzer
    # 1. Calls prepare on every aggregator
    # 2. Starts parsing every input source
    # 3. Calls aggregate for every parsed request on every aggregator
    # 4. Calls finalize on every aggregator
    # 5. Calls report on every aggregator
    def run!
      
      @filters.each { |filter| filter.prepare }
      @aggregators.each { |agg| agg.prepare }
      
      handle_request = Proc.new do |request|
        filter = @filters.detect { |filter| false == filter.filter(request) }
        @aggregators.each { |agg| agg.aggregate(request) } if filter.nil?
        filter.nil?
      end
        
      begin
        @sources.each do |source|
          case source
          when IO;     
            puts "Parsing from the standard input. Press CTRL+C to finish."
            @log_parser.parse_stream(source, options, &handle_request) 
          when String
            @log_parser.parse_file(source, options, &handle_request) 
          else
            raise "Unknown source provided"
          end
        end
      rescue Interrupt => e
        handle_progress(:interrupted)
        puts "Caught interrupt! Stopped parsing."
      end

      puts "\n"
      
      @aggregators.each { |agg| agg.finalize }
      @aggregators.each { |agg| agg.report(options[:report_width], options[:colorize]) }
    end
    
  end
end