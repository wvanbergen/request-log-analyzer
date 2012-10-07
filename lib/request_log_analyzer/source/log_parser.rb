module RequestLogAnalyzer::Source

  # The LogParser class reads log data from a given source and uses a file format definition
  # to parse all relevent information about requests from the file. A FileFormat module should
  # be provided that contains the definitions of the lines that occur in the log data.
  #
  # De order in which lines occur is used to combine lines to a single request. If these lines
  # are mixed, requests cannot be combined properly. This can be the case if data is written to
  # the log file simultaneously by different mongrel processes. This problem is detected by the
  # parser. It will emit warnings when this occurs. LogParser supports multiple parse strategies
  # that deal differently with this problem.
  class LogParser < Base

    include Enumerable

    # The maximum number of bytes to read from a line.
    DEFAULT_MAX_LINE_LENGTH = 8096

    DEFAULT_LINE_DIVIDER = "\n"

    # The default parse strategy that will be used to parse the input.
    DEFAULT_PARSE_STRATEGY = 'assume-correct'

    # All available parse strategies.
    PARSE_STRATEGIES = ['cautious', 'assume-correct']

    attr_reader :source_files, :current_file, :current_lineno, :processed_files
    attr_reader :warnings, :parsed_lines, :parsed_requests, :skipped_lines, :skipped_requests

    # Initializes the log file parser instance.
    # It will apply the language specific FileFormat module to this instance. It will use the line
    # definitions in this module to parse any input that it is given (see parse_io).
    #
    # <tt>format</tt>:: The current file format instance
    # <tt>options</tt>:: A hash of options that are used by the parser
    def initialize(format, options = {})
      super(format, options)
      @warnings         = 0
      @parsed_lines     = 0
      @parsed_requests  = 0
      @skipped_lines    = 0
      @skipped_requests = 0
      @current_request  = nil
      @current_source   = nil
      @current_file     = nil
      @current_lineno   = nil
      @processed_files  = []
      @source_files     = options[:source_files]
      @progress_handler = nil
      @warning_handler  = nil

      @options[:parse_strategy] ||= DEFAULT_PARSE_STRATEGY
      unless PARSE_STRATEGIES.include?(@options[:parse_strategy])
        raise "Unknown parse strategy: #{@options[@parse_strategy]}"
      end
    end

    def max_line_length
      file_format.max_line_length || DEFAULT_MAX_LINE_LENGTH
    end

    def line_divider
      file_format.line_divider || DEFAULT_LINE_DIVIDER
    end

    # Reads the input, which can either be a file, sequence of files or STDIN to parse
    # lines specified in the FileFormat. This lines will be combined into Request instances,
    # that will be yielded. The actual parsing occurs in the parse_io method.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def each_request(options = {}, &block) # :yields: :request, request

      case @source_files
      when IO
        if @source_files == $stdin
          puts "Parsing from the standard input. Press CTRL+C to finish." # FIXME: not here
        end
        parse_stream(@source_files, options, &block)
      when String
        parse_file(@source_files, options, &block)
      when Array
        parse_files(@source_files, options, &block)
      else
        raise "Unknown source provided"
      end
    end

    # Make sure the Enumerable methods work as expected
    alias_method :each, :each_request

    # Parses a list of subsequent files of the same format, by calling parse_file for every
    # file in the array.
    # <tt>files</tt>:: The Array of files that should be parsed
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def parse_files(files, options = {}, &block) # :yields: request
      files.each { |file| parse_file(file, options, &block) }
    end

    # Check if a file has a compressed extention in the filename.
    # If recognized, return the command string used to decompress the file
    def decompress_file?(filename)
      nice_command = "nice -n 5"

      return "#{nice_command} gunzip -c -d #{filename}" if filename.match(/\.tar.gz$/) || filename.match(/\.tgz$/) || filename.match(/\.gz$/)
      return "#{nice_command} bunzip2 -c -d #{filename}" if filename.match(/\.bz2$/)
      return "#{nice_command} unzip -p #{filename}" if filename.match(/\.zip$/)

      return ""
    end

    # Parses a log file. Creates an IO stream for the provided file, and sends it to parse_io for
    # further handling. This method supports progress updates that can be used to display a progressbar
    #
    # If the logfile is compressed, it is uncompressed to stdout and read.
    # TODO: Check if IO.popen encounters problems with the given command line.
    # TODO: Fix progress bar that is broken for IO.popen, as it returns a single string.
    #
    # <tt>file</tt>:: The file that should be parsed.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def parse_file(file, options = {}, &block)

      if File.directory?(file)
        parse_files(Dir["#{ file }/*"], options, &block)
        return
      end

      @current_source = File.expand_path(file)
      @source_changes_handler.call(:started, @current_source) if @source_changes_handler

      if decompress_file?(file).empty?

        @progress_handler = @dormant_progress_handler
        @progress_handler.call(:started, file) if @progress_handler

        File.open(file, 'rb') { |f| parse_io(f, options, &block) }

        @progress_handler.call(:finished, file) if @progress_handler
        @progress_handler = nil

        @processed_files.push(@current_source.dup)

      else
        IO.popen(decompress_file?(file), 'rb') { |f| parse_io(f, options, &block) }
      end

      @source_changes_handler.call(:finished, @current_source) if @source_changes_handler

      @current_source = nil

    end

    # Parses an IO stream. It will simply call parse_io. This function does not support progress updates
    # because the length of a stream is not known.
    # <tt>stream</tt>:: The IO stream that should be parsed.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def parse_stream(stream, options = {}, &block)
      parse_io(stream, options, &block)
    end

    # Parses a string. It will simply call parse_io. This function does not support progress updates.
    # <tt>string</tt>:: The string that should be parsed.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def parse_string(string, options = {}, &block)
      parse_io(StringIO.new(string), options, &block)
    end

    # This method loops over each line of the input stream. It will try to parse this line as any of
    # the lines that are defined by the current file format (see RequestLogAnalyazer::FileFormat).
    # It will then combine these parsed line into requests using heuristics. These requests (see
    # RequestLogAnalyzer::Request) will then be yielded for further processing in the pipeline.
    #
    # - RequestLogAnalyzer::LineDefinition#matches is called to test if a line matches a line definition of the file format.
    # - update_current_request is used to combine parsed lines into requests using heuristics.
    # - The method will yield progress updates if a progress handler is installed using progress=
    # - The method will yield parse warnings if a warning handler is installed using warning=
    #
    # This is a Ruby 1.9 specific version that offers memory protection.
    #
    # <tt>io</tt>:: The IO instance to use as source
    # <tt>options</tt>:: A hash of options that can be used by the parser.
    def parse_io_19(io, options = {}, &block) # :yields: request
      @max_line_length = options[:max_line_length] || max_line_length
      @line_divider    = options[:line_divider]    || line_divider
      @current_lineno  = 0
      while line = io.gets(@line_divider, @max_line_length)
        @current_lineno += 1
        @progress_handler.call(:progress, io.pos) if @progress_handler && @current_lineno % 255 == 0
        parse_line(line, &block)
      end

      warn(:unfinished_request_on_eof, "End of file reached, but last request was not completed!") unless @current_request.nil?
      @current_lineno = nil
    end

    # This method loops over each line of the input stream. It will try to parse this line as any of
    # the lines that are defined by the current file format (see RequestLogAnalyazer::FileFormat).
    # It will then combine these parsed line into requests using heuristics. These requests (see
    # RequestLogAnalyzer::Request) will then be yielded for further processing in the pipeline.
    #
    # - RequestLogAnalyzer::LineDefinition#matches is called to test if a line matches a line definition of the file format.
    # - update_current_request is used to combine parsed lines into requests using heuristics.
    # - The method will yield progress updates if a progress handler is installed using progress=
    # - The method will yield parse warnings if a warning handler is installed using warning=
    #
    # This is a Ruby 1.8 specific version that doesn't offer memory protection.
    #
    # <tt>io</tt>:: The IO instance to use as source
    # <tt>options</tt>:: A hash of options that can be used by the parser.
    def parse_io_18(io, options = {}, &block) # :yields: request
      @line_divider    = options[:line_divider]    || line_divider
      @current_lineno  = 0
      while line = io.gets(@line_divider)
        @current_lineno += 1
        @progress_handler.call(:progress, io.pos) if @progress_handler && @current_lineno % 255 == 0
        parse_line(line, &block)
      end

      warn(:unfinished_request_on_eof, "End of file reached, but last request was not completed!") unless @current_request.nil?
      @current_lineno = nil
    end

    alias_method :parse_io, RUBY_VERSION.to_f < 1.9 ? :parse_io_18 : :parse_io_19

    # Parses a single line using the current file format. If successful, use the parsed
    # information to build a request
    # <tt>line</tt>:: The line to parse
    # <tt>block</tt>:: The block to send fully parsed requests to.
    def parse_line(line, &block) # :yields: request
      if request_data = file_format.parse_line(line) { |wt, message| warn(wt, message) }
        @parsed_lines += 1
        update_current_request(request_data.merge(:source => @current_source, :lineno => @current_lineno), &block)
      end
    end

    # Add a block to this method to install a progress handler while parsing.
    # <tt>proc</tt>:: The proc that will be called to handle progress update messages
    def progress=(proc)
      @dormant_progress_handler = proc
    end

    # Add a block to this method to install a warning handler while parsing,
    # <tt>proc</tt>:: The proc that will be called to handle parse warning messages
    def warning=(proc)
      @warning_handler = proc
    end

    # Add a block to this method to install a source change handler while parsing,
    # <tt>proc</tt>:: The proc that will be called to handle source changes
    def source_changes=(proc)
      @source_changes_handler = proc
    end

    # This method is called by the parser if it encounteres any parsing problems.
    # It will call the installed warning handler if any.
    #
    # By default, RequestLogAnalyzer::Controller will install a warning handler
    # that will pass the warnings to each aggregator so they can do something useful
    # with it.
    #
    # <tt>type</tt>:: The warning type (a Symbol)
    # <tt>message</tt>:: A message explaining the warning
    def warn(type, message)
      @warnings += 1
      @warning_handler.call(type, message, @current_lineno) if @warning_handler
    end

    protected

    # Combines the different lines of a request into a single Request object. It will start a
    # new request when a header line is encountered en will emit the request when a footer line
    # is encountered.
    #
    # Combining the lines is done using heuristics. Problems can occur in this process. The
    # current parse strategy defines how these cases are handled.
    #
    # When using the 'assume-correct' parse strategy (default):
    # - Every line that is parsed before a header line is ignored as it cannot be included in
    #   any request. It will emit a :no_current_request warning.
    # - If a header line is found before the previous requests was closed, the previous request
    #   will be yielded and a new request will be started.
    #
    # When using the 'cautious' parse strategy:
    # - Every line that is parsed before a header line is ignored as it cannot be included in
    #   any request. It will emit a :no_current_request warning.
    # - A header line that is parsed before a request is closed by a footer line, is a sign of
    #   an unproperly ordered file. All data that is gathered for the request until then is
    #   discarded and the next request is ignored as well. An :unclosed_request warning is
    #   emitted.
    #
    # <tt>request_data</tt>:: A hash of data that was parsed from the last line.
    def update_current_request(request_data, &block) # :yields: request
      if alternative_header_line?(request_data)
        if @current_request
          @current_request << request_data
        else
          @current_request = @file_format.request(request_data)
        end
      elsif header_line?(request_data)
        if @current_request
          case options[:parse_strategy]
          when 'assume-correct'
            handle_request(@current_request, &block)
            @current_request = @file_format.request(request_data)
          when 'cautious'
            @skipped_lines += 1
            warn(:unclosed_request, "Encountered header line (#{request_data[:line_definition].name.inspect}), but previous request was not closed!")
            @current_request = nil # remove all data that was parsed, skip next request as well.
          end
        elsif footer_line?(request_data)
          handle_request(@file_format.request(request_data), &block)
        else
          @current_request = @file_format.request(request_data)
        end
      else
        if @current_request
          @current_request << request_data
          if footer_line?(request_data)
            handle_request(@current_request, &block) # yield @current_request
            @current_request = nil
          end
        else
          @skipped_lines += 1
          warn(:no_current_request, "Parseable line (#{request_data[:line_definition].name.inspect}) found outside of a request!")
        end
      end
    end

    # Handles the parsed request by sending it into the pipeline.
    #
    # - It will call RequestLogAnalyzer::Request#validate on the request instance
    # - It will send the request into the pipeline, checking whether it was accepted by all the filters.
    # - It will update the parsed_requests and skipped_requests variables accordingly
    #
    # <tt>request</tt>:: The parsed request instance (RequestLogAnalyzer::Request)
    def handle_request(request, &block) # :yields: :request, request
      @parsed_requests += 1
      request.validate
      accepted = block_given? ? yield(request) : true
      @skipped_requests += 1 unless accepted
    end


    # Checks whether a given line hash is an alternative header line according to the current file format.
    # <tt>hash</tt>:: A hash of data that was parsed from the line.
    def alternative_header_line?(hash)
      hash[:line_definition].header == :alternative
    end


    # Checks whether a given line hash is a header line according to the current file format.
    # <tt>hash</tt>:: A hash of data that was parsed from the line.
    def header_line?(hash)
      hash[:line_definition].header == true
    end

    # Checks whether a given line hash is a footer line  according to the current file format.
    # <tt>hash</tt>:: A hash of data that was parsed from the line.
    def footer_line?(hash)
      hash[:line_definition].footer
    end
  end
end
