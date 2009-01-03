module RequestLogAnalyzer
  
  module Anonymizers
    def anonymizer_for_ip(value, capture_definition)
      '127.0.0.1'
    end

    def anonymizer_for_url(value, capture_definition)
      value.sub(/^https?\:\/\/[A-z0-9\.-]+\//, "http://example.com/")
    end
  end  
  
  # The line definition class is used to specify what lines should be parsed from the log file.
  # It contains functionality to match a line against the definition and parse the information
  # from this line. This is used by the LogParser class when parsing a log file..
  class LineDefinition

    include RequestLogAnalyzer::Anonymizers

    class Definer
      
      attr_accessor :line_definitions
      
      def initialize
        @line_definitions = {}
      end
      
      def method_missing(name, *args, &block)
        if block_given?
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.define(name, &block)
        else
          @line_definitions[name] = RequestLogAnalyzer::LineDefinition.new(name, args.first)
        end
      end
    end

    attr_reader :name
    attr_accessor :teaser, :regexp, :captures
    attr_accessor :header, :footer
    
    # Initializes the LineDefinition instance with a hash containing the different elements of
    # the definition.
    def initialize(name, definition = {})
      @name     = name
      @captures = []
      definition.each { |key, value| self.send("#{key.to_s}=".to_sym, value) }
    end
    
    def self.define(name, &block)
      definition = self.new(name)
      yield(definition) if block_given?
      return definition
    end
    
    # Converts a parsed value (String) to the desired value using some heuristics.
    def convert_value(value, type)
      case type
      when :integer;   value.to_i
      when :float;     value.to_f
      when :decimal;   value.to_f          
      when :symbol;    value.to_sym
      when :sec;       value.to_f
      when :msec;      value.to_f / 1000
      when :timestamp; value.gsub(/[^0-9]/,'')[0..13].to_i # Retrieve with: DateTime.parse(value, '%Y%m%d%H%M%S')
      else value
      end
    end
    
    # Checks whether a given line matches this definition. 
    # It will return false if a line does not match. If the line matches, a hash is returned
    # with all the fields parsed from that line as content.
    # If the line definition has a teaser-check, a :teaser_check_failed warning will be emitted
    # if this teaser-check is passed, but the full regular exprssion does not ,atch.
    def matches(line, lineno = nil, parser = nil)
      if @teaser.nil? || @teaser =~ line
        if match_data = line.match(@regexp)
          request_info = { :line_type => name, :lineno => lineno }
          
          captures.each_with_index do |capture, index|
            next if capture == :ignore

            if match_data.captures[index]
              request_info[capture[:name]] = convert_value(match_data.captures[index], capture[:type])
            end

          end
          return request_info
        else
          if @teaser && parser
            parser.warn(:teaser_check_failed, "Teaser matched for #{name.inspect}, but full line did not:\n#{line.inspect}")
          end
          return false
        end
      else
        return false
      end
    end
    
    alias :=~ :matches
    
    def anonymize_value(value, capture_definition)
      if capture_definition[:anonymize].respond_to?(:call)
        capture_definition[:anonymize].call(value, capture_definition)
      else
        case capture_definition[:anonymize]
        when nil;   value
        when false; value
        when true;  '***'
        when :slightly; anonymize_slightly(value, capture_definition)
        else 
          method_name = "anonymizer_for_#{capture_definition[:anonymize]}".to_sym
          self.respond_to?(method_name) ? self.send(method_name, value, capture_definition) : '***'
        end
      end
    end
    
    def anonymize_slightly(value, capture_definition)  
      case capture_definition[:type]
      when :integer
        (value.to_i * (0.8 + rand * 0.4)).to_i
      when :double
        (value.to_f * (0.8 + rand * 0.4)).to_f          
      when :msec
        (value.to_i * (0.8 + rand * 0.4)).to_i
      when :sec
        (value.to_f * (0.8 + rand * 0.4)).to_f
      when :timestamp
        (DateTime.parse(value) + (rand(100) - 50)).to_s
      else
        puts "Cannot anonymize #{capture_definition[:type].inspect} slightly, using ***"
        '***'
      end  
    end

    # Anonymize a log line
    def anonymize(line, options = {})
      if self.teaser.nil? || self.teaser =~ line
        if self.regexp =~ line
          pos_adjustment = 0
          captures.each_with_index do |capture, index|
            unless $~[index + 1].nil?
              anonymized_value = anonymize_value($~[index + 1], capture).to_s
              line[($~.begin(index + 1) + pos_adjustment)...($~.end(index + 1) + pos_adjustment)] = anonymized_value
              pos_adjustment += anonymized_value.length - $~[index + 1].length                    
            end
          end
          line
        elsif self.teaser.nil?
          nil
        else
          options[:discard_teaser_lines] ? "" : line
        end
      else
        nil
      end
    end
  end
  
end