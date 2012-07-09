module RequestLogAnalyzer

  # The RequestLogAnalyzer::Controller class creates a LogParser instance for the
  # requested file format and connect it with sources and aggregators.
  #
  # Sources are streams or files from which the requests will be parsed.
  # Aggregators will handle every passed request to yield a meaningfull results.
  #
  # - Use the build -function to build a new controller instance.
  # - Use the run! method to start the parser and send the requests to the aggregators.
  #
  # Note that the order of sources can be imported if you have log files than succeed
  # eachother. Requests that span over succeeding files will be parsed correctly if the
  # sources are registered in the correct order. This can be helpful to parse requests
  # from several logrotated log files.
  class Controller

    attr_reader :source, :filters, :aggregators, :output, :options

    # Builds a RequestLogAnalyzer::Controller given parsed command line arguments
    # <tt>arguments<tt> A CommandLine::Arguments hash containing parsed commandline parameters.
    def self.build_from_arguments(arguments)

      options = {}

      # Copy fields
      options[:database]       = arguments[:database]
      options[:reset_database] = arguments[:reset_database]
      options[:debug]          = arguments[:debug]
      options[:yaml]           = arguments[:yaml] || arguments[:dump]
      options[:mail]           = arguments[:mail]
      options[:no_progress]    = arguments[:no_progress]
      options[:format]         = arguments[:format]
      options[:output]         = arguments[:output]
      options[:file]           = arguments[:file]
      options[:after]          = arguments[:after]
      options[:before]         = arguments[:before]
      options[:reject]         = arguments[:reject]
      options[:select]         = arguments[:select]
      options[:boring]         = arguments[:boring]
      options[:aggregator]     = arguments[:aggregator]
      options[:report_width]   = arguments[:report_width]
      options[:report_sort]    = arguments[:report_sort]
      options[:report_amount]  = arguments[:report_amount]
      options[:mailhost]       = arguments[:mailhost]
      options[:mailsubject]    = arguments[:mailsubject]
      options[:silent]         = arguments[:silent]
      options[:parse_strategy] = arguments[:parse_strategy]

      # Apache format workaround
      if arguments[:rails_format]
        options[:format] = {:rails => arguments[:rails_format]}
      elsif arguments[:apache_format]
        options[:format] = {:apache => arguments[:apache_format]}
      end

      # Handle output format casing
      if options[:output].class == String
        options[:output] = 'HTML'       if options[:output] =~ /^html$/i
        options[:output] = 'FixedWidth' if options[:output] =~ /^fixed_?width$/i
      end

      # Register sources
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

      # Guess file format
      if !options[:format] && options[:source_files]
        options[:format] = :rails3 # Default

        if options[:source_files] != $stdin
          if options[:source_files].class == String
            options[:format] = RequestLogAnalyzer::FileFormat.autodetect(options[:source_files])

          elsif options[:source_files].class == Array && options[:source_files].first != $stdin
            options[:format] = RequestLogAnalyzer::FileFormat.autodetect(options[:source_files].first)
          end
        end
      end

      build(options)
    end

    # Build a new controller.
    # Returns a new RequestLogAnalyzer::Controller object.
    #
    # Options
    # * <tt>:after</tt> Drop all requests after this date (Date, DateTime, Time, or a String in "YYYY-MM-DD hh:mm:ss" format)
    # * <tt>:aggregator</tt> Array of aggregators (Strings or Symbols for the builtin aggregators or a RequestLogAnalyzer::Aggregator class - Defaults to [:summarizer]).
    # * <tt>:boring</tt> Do not show color on STDOUT (Defaults to false).
    # * <tt>:before</tt> Drop all requests before this date (Date, DateTime, Time or a String in "YYYY-MM-DD hh:mm:ss" format)
    # * <tt>:database</tt> Database file to insert encountered requests to.
    # * <tt>:debug</tt> Enables echo aggregator which will echo each request analyzed.
    # * <tt>:file</tt> Filestring, File or StringIO.
    # * <tt>:format</tt> :rails, {:apache => 'FORMATSTRING'}, :merb, :amazon_s3, :mysql or RequestLogAnalyzer::FileFormat class. (Defaults to :rails).
    # * <tt>:mail</tt> Email the results to this email address.
    # * <tt>:mailhost</tt> Email the results to this mail server.
    # * <tt>:mailsubject</tt> Email subject.
    # * <tt>:no_progress</tt> Do not display the progress bar (increases parsing speed).
    # * <tt>:output</tt> 'FixedWidth', 'HTML' or RequestLogAnalyzer::Output class. Defaults to 'FixedWidth'.
    # * <tt>:reject</tt> Reject specific {:field => :value} combination (expects a single hash).
    # * <tt>:report_width</tt> Width of reports in characters for FixedWidth reports. (Defaults to 80)
    # * <tt>:reset_database</tt> Reset the database before starting.
    # * <tt>:select</tt> Select specific {:field => :value} combination (expects a single hash).
    # * <tt>:source_files</tt> Source files to analyze. Provide either File, array of files or STDIN.
    # * <tt>:yaml</tt> Output to YAML file.
    # * <tt>:silent</tt> Minimal output automatically implies :no_progress
    # * <tt>:source</tt> The class to instantiate to grab the requestes, must be a RequestLogAnalyzer::Source::Base descendant. (Defaults to RequestLogAnalyzer::Source::LogParser)
    #
    # === Example
    # RequestLogAnalyzer::Controller.build(
    #   :output       => :HTML,
    #   :mail         => 'root@localhost',
    #   :after        => Time.now - 24*60*60,
    #   :source_files => '/var/log/passenger.log'
    # ).run!
    #
    # === Todo
    # * Check if defaults work (Aggregator defaults seem wrong).
    # * Refactor :database => options[:database], :dump => options[:dump] away from contoller intialization.
    def self.build(options)
      # Defaults
      options[:output]        ||= 'FixedWidth'
      options[:format]        ||= :rails
      options[:aggregator]    ||= [:summarizer]
      options[:report_width]  ||= 80
      options[:report_amount] ||= 20
      options[:report_sort]   ||= 'sum,mean'
      options[:boring]        ||= false
      options[:silent]        ||= false
      options[:source]        ||= RequestLogAnalyzer::Source::LogParser

      options[:no_progress] = true if options[:silent]

      # Deprecation warnings
      if options[:dump]
        warn "[DEPRECATION] `:dump` is deprecated.  Please use `:yaml` instead."
        options[:yaml]          = options[:dump]
      end

      # Set the output class
      output_args   = {}
      output_object = nil
      if options[:output].is_a?(Class)
        output_class = options[:output]
      else
        output_class = RequestLogAnalyzer::Output.const_get(options[:output])
      end

      output_sort   = options[:report_sort].split(',').map { |s| s.to_sym }
      output_amount = options[:report_amount] == 'all' ? :all : options[:report_amount].to_i

      if options[:file]
        output_object = %w[File StringIO].include?(options[:file].class.name) ? options[:file] : File.new(options[:file], "w+")
        output_args   = {:width => 80, :color => false, :characters => :ascii, :sort => output_sort, :amount => output_amount }
      elsif options[:mail]
        output_object = RequestLogAnalyzer::Mailer.new(options[:mail], options[:mailhost], :subject => options[:mailsubject])
        output_args   = {:width => 80, :color => false, :characters => :ascii, :sort => output_sort, :amount => output_amount  }
      else
        output_object = STDOUT
        output_args   = {:width => options[:report_width].to_i, :color => !options[:boring],
                        :characters => (options[:boring] ? :ascii : :utf), :sort => output_sort, :amount => output_amount }
      end

      output_instance = output_class.new(output_object, output_args)

      # Create the controller with the correct file format
      if options[:format].kind_of?(Hash)
        file_format = RequestLogAnalyzer::FileFormat.load(options[:format].keys[0], options[:format].values[0])
      else
        file_format = RequestLogAnalyzer::FileFormat.load(options[:format])
      end

      # Kickstart the controller
      controller =
        Controller.new(options[:source].new(file_format,
                                            :source_files => options[:source_files],
                                            :parse_strategy => options[:parse_strategy]),
                       { :output         => output_instance,
                         :database       => options[:database],                # FUGLY!
                         :yaml           => options[:yaml],
                         :reset_database => options[:reset_database],
                         :no_progress    => options[:no_progress],
                         :silent         => options[:silent]
                       })

      # register filters
      if options[:after] || options[:before]
        filter_options = {}
        [:after, :before].each do |filter|
          case options[filter]
          when Date, DateTime, Time
            filter_options[filter] = options[filter]
          when String
            filter_options[filter] = DateTime.parse(options[filter])
          end
        end
        controller.add_filter(:timespan, filter_options)
      end

      if options[:reject]
        options[:reject].each do |(field, value)|
          controller.add_filter(:field, :mode => :reject, :field => field, :value => value)
        end
      end

      if options[:select]
        options[:select].each do |(field, value)|
          controller.add_filter(:field, :mode => :select, :field => field, :value => value)
        end
      end

      # register aggregators
      options[:aggregator].each { |agg| controller.add_aggregator(agg) }
      controller.add_aggregator(:summarizer)          if options[:aggregator].empty?
      controller.add_aggregator(:echo)                if options[:debug]
      controller.add_aggregator(:database_inserter)   if options[:database] && !options[:aggregator].include?('database')

      file_format.setup_environment(controller)
      return controller
    end

    # Builds a new Controller for the given log file format.
    # <tt>format</tt> Logfile format. Defaults to :rails
    # Options are passd on to the LogParser.
    # * <tt>:database</tt> Database the controller should use.
    # * <tt>:yaml</tt> Yaml Dump the contrller should use.
    # * <tt>:output</tt> All report outputs get << through this output.
    # * <tt>:no_progress</tt> No progress bar
    # * <tt>:silent</tt> Minimal output, only error
    def initialize(source, options = {})

      @source      = source
      @options     = options
      @aggregators = []
      @filters     = []
      @output      = options[:output]
      @interrupted = false

      # Register the request format for this session after checking its validity
      raise "Invalid file format!" unless @source.file_format.valid?

      # Install event handlers for wrnings, progress updates and source changes
      @source.warning        = lambda { |type, message, lineno|  @aggregators.each { |agg| agg.warning(type, message, lineno) } }
      @source.progress       = lambda { |message, value| handle_progress(message, value) } unless options[:no_progress]
      @source.source_changes = lambda { |change, filename| handle_source_change(change, filename) }
    end

    # Progress function.
    # Expects :started with file, :progress with current line and :finished or :interrupted when done.
    # <tt>message</tt> Current state (:started, :finished, :interupted or :progress).
    # <tt>value</tt> File or current line.
    def handle_progress(message, value = nil)
      case message
      when :started
        @progress_bar = CommandLine::ProgressBar.new(File.basename(value), File.size(value), STDERR)
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

    # Source change handler
    def handle_source_change(change, filename)
      @aggregators.each { |agg| agg.source_change(change, File.expand_path(filename, Dir.pwd)) }
    end

    # Adds an aggregator to the controller. The aggregator will be called for every request
    # that is parsed from the provided sources (see add_source)
    def add_aggregator(agg)
      agg = RequestLogAnalyzer::Aggregator.const_get(RequestLogAnalyzer.to_camelcase(agg)) if agg.kind_of?(String) || agg.kind_of?(Symbol)
      @aggregators << agg.new(@source, @options)
    end

    alias :>> :add_aggregator

    # Adds a request filter to the controller.
    def add_filter(filter, filter_options = {})
      filter = RequestLogAnalyzer::Filter.const_get(RequestLogAnalyzer.to_camelcase(filter)) if filter.kind_of?(Symbol)
      @filters << filter.new(source.file_format, @options.merge(filter_options))
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
      return false unless request
      @aggregators.each { |agg| agg.aggregate(request) }
      return true
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

      # @aggregators.each{|agg| p agg}

      @aggregators.each { |agg| agg.prepare }
      install_signal_handlers

      @source.each_request do |request|
        break if @interrupted
        aggregate_request(filter_request(request))
      end

      @aggregators.each { |agg| agg.finalize }

      @output.header
      @aggregators.each { |agg| agg.report(@output) }
      @output.footer

      @source.finalize

      if @output.io.kind_of?(File)
        unless @options[:silent]
          puts
          puts "Report written to: " + File.expand_path(@output.io.path)
          puts "Need an expert to analyze your application?"
          puts "Mail to contact@railsdoctors.com or visit us at http://railsdoctors.com"
          puts "Thanks for using request-log-analyzer!"
        end
        @output.io.close
      elsif @output.io.kind_of?(RequestLogAnalyzer::Mailer)
        @output.io.mail
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
