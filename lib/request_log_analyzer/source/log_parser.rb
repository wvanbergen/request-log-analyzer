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

    # The default parse strategy that will be used to parse the input.
    DEFAULT_PARSE_STRATEGY = 'assume-correct'
    
    # All available parse strategies.
    PARSE_STRATEGIES = ['cautious', 'assume-correct']

    attr_reader :source_files

    # Initializes the log file parser instance.
    # It will apply the language specific FileFormat module to this instance. It will use the line
    # definitions in this module to parse any input that it is given (see parse_io).
    #
    # <tt>format</tt>:: The current file format instance
    # <tt>options</tt>:: A hash of options that are used by the parser
    def initialize(format, options = {})      
      @line_definitions = {}
      @options          = options
      @parsed_lines     = 0
      @parsed_requests  = 0
      @skipped_lines    = 0
      @skipped_requests = 0
      @current_io       = nil
      @source_files     = options[:source_files]
      
      @options[:parse_strategy] ||= DEFAULT_PARSE_STRATEGY
      raise "Unknown parse strategy" unless PARSE_STRATEGIES.include?(@options[:parse_strategy])
      
      self.register_file_format(format)
    end
    
    # Reads the input, which can either be a file, sequence of files or STDIN to parse
    # lines specified in the FileFormat. This lines will be combined into Request instances,
    # that will be yielded. The actual parsing occurs in the parse_io method.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def each_request(options = {}, &block) # :yields: request
      
      case @source_files
      when IO;     
        puts "Parsing from the standard input. Press CTRL+C to finish."
        parse_stream(@source_files, options, &block) 
      when String
        parse_file(@source_files, options, &block) 
      when Array
        parse_files(@source_files, options, &block) 
      else
        raise "Unknown source provided"
      end
    end

    # Parses a list of subsequent files of the same format, by calling parse_file for every
    # file in the array.
    # <tt>files</tt>:: The Array of files that should be parsed
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def parse_files(files, options = {}, &block) # :yields: request
      files.each { |file| parse_file(file, options, &block) }
    end

    # Parses a log file. Creates an IO stream for the provided file, and sends it to parse_io for
    # further handling. This method supports progress updates that can be used to display a progressbar
    # <tt>file</tt>:: The file that should be parsed.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.    
    def parse_file(file, options = {}, &block)
      @progress_handler.call(:started, file) if @progress_handler
      File.open(file, 'r') { |f| parse_io(f, options, &block) }
      @progress_handler.call(:finished, file) if @progress_handler
    end


    # Parses an IO stream. It will simply call parse_io. This function does not support progress updates
    # because the length of a stream is not known.
    # <tt>stream</tt>:: The IO stream that should be parsed.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.    
    def parse_stream(stream, options = {}, &block)
      parse_io(stream, options, &block)
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
    # <tt>io</tt>:: The IO instance to use as source
    # <tt>options</tt>:: A hash of options that can be used by the parser.
    def parse_io(io, options = {}, &block) # :yields: request

      @current_io = io
      @current_io.each_line do |line|

        @progress_handler.call(:progress, @current_io.pos) if @progress_handler && @current_io.kind_of?(File)

        request_data = nil
        file_format.line_definitions.each do |line_type, definition|
          request_data = definition.matches(line, @current_io.lineno, self)
          break if request_data
        end
        
        if request_data
          @parsed_lines += 1
          update_current_request(request_data, &block)
        end
      end

      warn(:unfinished_request_on_eof, "End of file reached, but last request was not completed!") unless @current_request.nil?

      @current_io = nil
    end

    # Add a block to this method to install a progress handler while parsing.
    # <tt>proc</tt>:: The proc that will be called to handle progress update messages
    def progress=(proc)
      @progress_handler = proc
    end

    # Add a block to this method to install a warning handler while parsing,
    # <tt>proc</tt>:: The proc that will be called to handle parse warning messages    
    def warning=(proc)
      @warning_handler = proc
    end

    # This method is called by the parser if it encounteres any problems.
    # It will call the warning handler. The default controller will pass all warnings to every
    # aggregator that is registered and running
    def warn(type, message)
      @warning_handler.call(type, message, @current_io.lineno) if @warning_handler
    end

    protected

    # Combines the different lines of a request into a single Request object. It will start a 
    # new request when a header line is encountered en will emit the request when a footer line 
    # is encountered.
    #
    # - Every line that is parsed before a header line is ignored as it cannot be included in 
    #   any request. It will emit a :no_current_request warning.
    # - A header line that is parsed before a request is closed by a footer line, is a sign of
    #   an unprpertly ordered file. All data that is gathered for the request until then is 
    #   discarded, the next request is ignored as well and a :unclosed_request warning is
    #   emitted.
    def update_current_request(request_data, &block)
      if header_line?(request_data)
        unless @current_request.nil?
          case options[:parse_strategy]
          when 'assume-correct'
            handle_request(@current_request, &block)
            @current_request = @file_format.request(request_data)
          when 'cautious'
            @skipped_lines += 1
            warn(:unclosed_request, "Encountered header line (#{request_data[:line_definition].name.inspect}), but previous request was not closed!")
            @current_request = nil # remove all data that was parsed, skip next request as well.
          end
        else
          @current_request = @file_format.request(request_data)              
        end
      else
        unless @current_request.nil?
          @current_request << request_data
          if footer_line?(request_data)
            handle_request(@current_request, &block) # yield @current_request
            @current_request = nil 
          end
        else
          @skipped_lines += 1
          warn(:no_current_request, "Parsebale line (#{request_data[:line_definition].name.inspect}) found outside of a request!")
        end
      end
    end
    
    # Handles the parsed request by calling the request handler.
    # The default controller will send the request to every running aggegator.
    def handle_request(request, &block)
      @parsed_requests += 1
      request.validate
      accepted = block_given? ? yield(request) : true
      @skipped_requests += 1 if not accepted
    end    

    # Checks whether a given line hash is a header line.
    def header_line?(hash)
      hash[:line_definition].header
    end

    # Checks whether a given line hash is a footer line.    
    def footer_line?(hash)
      hash[:line_definition].footer
    end 
  end

end
