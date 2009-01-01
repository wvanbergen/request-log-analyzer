module RequestLogAnalyzer
  
  class LogAnonymizer
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :input_file, :output_file, :options
   
    def self.build(arguments)
      
      options = { 
          :discard_teaser_lines => arguments[:discard_teaser_lines], 
          :keep_junk_lines      => arguments[:keep_junk_lines], 
          :strip                => arguments[:strip] 
        }
          
      input_file  = arguments.parameters[0]
      suffix = options[:strip] ? '.stripped' : '.anonymized'
      output_file = arguments.parameters[1] || input_file + suffix
      
      log_anonymizer = RequestLogAnalyzer::LogAnonymizer.new(arguments[:format].to_sym, input_file, output_file, options)
    end
    
    def initialize(format, input_file, output_file, options = {})
      @input_file  = input_file
      @output_file = output_file
      @options     = options
      
      self.register_file_format(format)
    end
    
    def strip_line(line)
      file_format.line_definitions.any? { |name, definition| definition =~ line } ? line : ""
    end

    def strip_file
      File.open(output_file, 'w') do |output|
        File.open(input_file, 'r') do |input|          
          input.each_line { |line| output << strip_line(line) }
        end
      end
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
    
    def anonymize_file
      File.open(output_file, 'w') do |output|
        File.open(input_file, 'r') do |input|          
          input.each_line { |line| output << anonymize_line(line) }
        end
      end
    end
    
    def run!
      options[:strip] ? strip_file : anonymize_file
    end
  end

end