module RequestLogAnalyzer
  
  class LogAnonymizer
    
    include RequestLogAnalyzer::FileFormat
    
    attr_reader :input_file, :output_file, :options
   
    def self.build(arguments)
      
      options = { 
          :discard_teaser_lines => arguments[:discard_teaser_lines], 
          :keep_junk_lines      => arguments[:keep_junk_lines] 
        }
          
      input_file  = arguments.parameters[0]
      output_file = arguments.parameters[1] || input_file + '.anonymized'
      
      log_anonymizer = RequestLogAnalyzer::LogAnonymizer.new(arguments[:format].to_sym, input_file, output_file, options)
    end
    
    def initialize(format, input_file, output_file, options = {})
      @input_file  = input_file
      @output_file = output_file
      @options     = options
      
      self.register_file_format(format)
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
      anonymize_file
    end
  end

end