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

    include RequestLogAnalyzer::FileFormat
    
    attr_reader :aggregators
    attr_reader :log_parser
    attr_reader :sources
    attr_reader :options

    # Builds a RequestLogAnalyzer::Controller given parsed command line arguments
    # <tt>arguments<tt> A CommandLine::Arguments hash containing parsed commandline parameters.
    def self.build(arguments)
      
      if arguments[:debug]
        print "Parsing mode: "
        puts arguments[:combined_requests] ? 'combined requests' : 'single lines'
      end
      
      options = {}
      options[:combined_requests] = arguments[:combined_requests]
      options[:database] = arguments[:database] if arguments[:database]

      # Create the controller with the correct file format
      controller = Controller.new(arguments[:format].to_sym, options)

      # register sources
      arguments.parameters.each do |file|
        controller.add_source(file) if File.exist?(file)
      end

      # register aggregators
      arguments[:aggregator].each { |agg| controller >> agg.to_sym } 

      # register the database 
      controller.add_aggregator(:database) if arguments[:database] && !arguments[:aggregator].include?('database')
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
    def initialize(format = :rails, options = {})

      @options = options
      @aggregators = []
      @sources     = []
      
      # Requester format through RequestLogAnalyzer::FileFormat and construct the parser
      register_file_format(format) 
      @log_parser  = RequestLogAnalyzer::LogParser.new(file_format, @options)
      
      # Pass all warnings to every aggregator so they can do something useful with them.
      @log_parser.on_warning do |type, message, lineno|        
        @aggregators.each { |agg| agg.warning(type, message, lineno) }
        puts "WARNING #{type.inspect} on line #{lineno}: #{message}" unless options[:silent]
      end
    end
    
    # Adds an aggregator to the controller. The aggregator will be called for every request 
    # that is parsed from the provided sources (see add_source)
    def add_aggregator(agg)
      if agg.kind_of?(Symbol)
        require File.dirname(__FILE__) + "/aggregator/#{agg}"
        agg = RequestLogAnalyzer::Aggregator.const_get(agg.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join(''))
      end
      
      @aggregators << agg.new(file_format, @options)
    end
    
    alias :>> :add_aggregator
    
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
      
      @aggregators.each { |agg| agg.prepare }
      
      handle_request = Proc.new { |request| @aggregators.each { |agg| agg.aggregate(request) } }
      @sources.each do |source|
        case source
        when IO;     @log_parser.parse_io(source, options,   &handle_request) 
        when String; @log_parser.parse_file(source, options, &handle_request) 
        else;        raise "Unknwon source provided"
        end
      end
      
      @aggregators.each { |agg| agg.finalize }
      @aggregators.each { |agg| agg.report(options[:colorize]) }
    end
    
  end
end