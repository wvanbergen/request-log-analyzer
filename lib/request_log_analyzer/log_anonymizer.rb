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
    
    def anonymizer_for_ip(value, capture_definition)
      '127.0.0.1'
    end
    
    def anonymizer_for_slightly(value, capture_definition)
      case capture_definition[:type]
      when :msec
        (value.to_i * (0.8 + (rand(400) / 1000))).to_i
      when :sec
        (value.to_f * (0.8 + (rand(400) / 1000))).to_f
      when :timestamp
        (DateTime.parse(value) + (rand(100) - 50)).to_s
      else
        puts "Cannot anonymize #{capture_definition[:type].inspect} slightly, using ***"
        '***'
      end
    end
    
    def anonymizer_for_url(value, capture_definition)
      value.sub(/^https?\:\/\/[A-z0-9\.-]+\//, "http://example.com/")
    end
    
    def anonymize_value(value, capture_definition)
      case capture_definition[:anonymize]
      when nil;   value
      when false; value
      when true;  '***'
      else 
        method_name = "anonymizer_for_#{capture_definition[:anonymize]}".to_sym
        if self.respond_to?(method_name)
          self.send(method_name, value, capture_definition)
        else
          puts "Anonymizer function net found: #{method_name}"
          return '***'
        end
      end
    end
    
    def anonymize_file
      File.open(output_file, 'w') do |output|
        File.open(input_file, 'r') do |input|        
          
          input.each_line do |line|

            name, definition = file_format.line_definitions.detect { |name, definition| definition.teaser =~ line }
            if definition
              if definition.regexp =~ line
                pos_adjustment = 0
                definition.captures.each_with_index do |capture, index|
                  unless $~[index + 1].nil?
                    anonymized_value = anonymize_value($~[index + 1], capture).to_s
                    line[($~.begin(index + 1) + pos_adjustment)...($~.end(index + 1) + pos_adjustment)] = anonymized_value
                    pos_adjustment += anonymized_value.length - $~[index + 1].length                    
                  end
                end
                output << line
              else
                output << line unless options[:discard_teaser_lines]
              end
            else
              output << line if options[:keep_junk_lines]
            end
          end
        end
      end
    end
    
    def run!
      anonymize_file
    end
  end

end