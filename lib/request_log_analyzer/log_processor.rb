module RequestLogAnalyzer
  
  class LogProcessor
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :mode, :options, :sources
    attr_accessor :output_file
   
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
    
    def initialize(format, mode, options = {})
      @options = options
      @mode    = mode
      @sources = []
      $output_file = nil
      self.register_file_format(format)
    end
    
    def process_file(file)
      File.open(file, 'r') { |file| process_io(file) }
    end

    def process_io(io)
      case mode
        when :strip;     io.each_line { |line| @output << strip_line(line) }
        when :anonymize; io.each_line { |line| @output << anonymize_line(line) }
      end
    end

    def strip_line(line)
      file_format.line_definitions.any? { |name, definition| definition =~ line } ? line : ""
    end

    def anonymize_line(line)
      anonymized_line = nil
      file_format.line_definitions.detect { |name, definition| anonymized_line = definition.anonymize(line, options) }
      
      if anonymized_line
        return anonymized_line
      elsif options[:keep_junk_lines]
        return line
      else
        return ""
      end
    end

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