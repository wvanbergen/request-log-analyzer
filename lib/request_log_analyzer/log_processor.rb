module RequestLogAnalyzer

  # The Logprocessor class is used to perform simple processing actions over log files.
  # It will go over the log file/stream line by line, pass the line to a processor and
  # write the result back to the output file or stream. The processor can alter the
  # contents of the line, remain it intact or remove it altogether, based on the current
  # file format
  #
  # Currently, one processors is supported:
  #  * :strip will remove all irrelevent lines (according to the file format) from the
  #    sources. A compact, information packed log will remain/.
  #
  class LogProcessor

    attr_reader :mode, :options, :sources, :file_format
    attr_accessor :output_file

    # Builds a logprocessor instance from the arguments given on the command line
    # <tt>command</tt> The command hat was used to start the log processor. This will set the
    #    processing mode. Currently, only :strip is supported.
    # <tt>arguments</tt> The parsed command line arguments (a CommandLine::Arguments instance)
    def self.build(command, arguments)

      options = {
          :discard_teaser_lines => arguments[:discard_teaser_lines],
          :keep_junk_lines      => arguments[:keep_junk_lines],
        }

      log_processor = RequestLogAnalyzer::LogProcessor.new(arguments[:format].to_sym, command, options)
      log_processor.output_file = arguments[:output] if arguments[:output]

      arguments.parameters.each do |input|
        log_processor.sources << input
      end

      return log_processor
    end

    # Initializes a new LogProcessor instance.
    # <tt>format</tt> The file format to use (e.g. :rails).
    # <tt>mode</tt> The processing mode
    # <tt>options</tt> A hash with options to take into account
    def initialize(format, mode, options = {})
      @options     = options
      @mode        = mode
      @sources     = []
      @file_format = format
      $output_file = nil
    end

    # Processes input files by opening it and sending the filestream to <code>process_io</code>,
    # in which the actual processing is performed.
    # <tt>file</tt> The file to process
    def process_file(file)
      File.open(file, 'r') { |io| process_io(io) }
    end

    # Processes an input stream by iteration over each line and processing it according to
    # the current operation mode
    # <tt>io</tt> The IO instance to process.
    def process_io(io)
      case mode
        when :strip;     io.each_line { |line| @output << strip_line(line) }
      end
    end

    # Returns the line itself if the string matches any of the line definitions. If no match is
    # found, an empty line is returned, which will strip the line from the output.
    # <tt>line</tt> The line to strip
    def strip_line(line)
      file_format.line_definitions.any? { |name, definition| definition =~ line } ? line : ""
    end

    # Runs the log processing by setting up the output stream and iterating over all the
    # input sources. Input sources can either be filenames (String instances) or IO streams
    # (IO instances). The strings "-" and "STDIN" will be substituted for the $stdin variable.
    def run!
      if @output_file.nil?
        @output = $stdout
      else
        @output = File.new(@output_file, 'a')
      end

      @sources.each do |source|
        if source.kind_of?(String) && File.exist?(source)
          process_file(source)
        elsif source.kind_of?(IO)
          process_io(source)
        elsif ['-', 'STDIN'].include?(source)
          process_io($stdin)
        end
      end

    ensure
      @output.close if @output.kind_of?(File)
    end
  end

end