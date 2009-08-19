module RequestLogAnalyzer
  
  # The Request class represents a parsed request from the log file. 
  # Instances are created by the LogParser and are passed to the different aggregators, so they
  # can do their aggregating work. 
  #
  # This class provides several methods to access the data that was parsed from the log files.
  # Request#first(field_name) returns the first (only) value corresponding to the given field
  # Request#every(field_name) returns all values corresponding to the given field name as array.
  class Request
  
    module Converters
      
      def convert_value(value, capture_definition)
        custom_converter_method = "convert_#{capture_definition[:type]}".to_sym
        if respond_to?(custom_converter_method) 
          send(custom_converter_method, value, capture_definition)
        elsif !value.nil? 
          case capture_definition[:type]
          when :decimal;  value.to_f
          when :float;    value.to_f
          when :double;   value.to_f
          when :integer;  value.to_i
          when :int;      value.to_i
          when :symbol;   value.to_sym
          else;           value.to_s
          end
        else 
          nil
        end
      end
      
      def convert_eval(value, capture_definition)
        eval(value).inject({}) { |h, (k, v)| h[k.to_sym] = v; h} 
      rescue SyntaxError
        nil
      end
      
      # Slow default method to parse timestamps
      def convert_timestamp(value, capture_definition)
        DateTime.parse(value).strftime('%Y%m%d%H%M%S').to_i unless value.nil?
      end
      
      def convert_duration(value, capture_definition)
        if value.nil?
          nil
        elsif capture_definition[:unit] == :msec
          value.to_f / 1000.0      
        else
          value.to_f
        end
      end
    end
  
    include RequestLogAnalyzer::FileFormat::Awareness
    include Converters
  
    attr_reader :lines
    attr_reader :attributes
        
    # Initializes a new Request object. 
    # It will apply the the provided FileFormat module to this instance.
    def initialize(file_format, attributes = {})
      @lines = []
      @attributes = attributes
      register_file_format(file_format)
    end
    
    # Creates a new request that was parsed from the log with the given FileFormat. The hashes
    # that are passed to this function are added as lines to this request.
    def self.create(file_format, *hashes)
      request = self.new(file_format)
      hashes.flatten.each { |hash| request << hash }
      return request
    end
     
    # Adds another line to the request.
    # The line should be provides as a hash of the fields parsed from the line.
    def add_parsed_line (parsed_line)
      value_hash = parsed_line[:line_definition].convert_captured_values(parsed_line[:captures], self)
      value_hash[:line_type] = parsed_line[:line_definition].name
      value_hash[:lineno] = parsed_line[:lineno]
      add_line_hash(value_hash)
    end
    
    def add_line_hash(value_hash)
      @lines << value_hash
      @attributes = value_hash.merge(@attributes)      
    end
    
    
    def <<(hash)
      hash[:line_definition] ? add_parsed_line(hash) : add_line_hash(hash)
    end
    
    # Checks whether the given line type was parsed from the log file for this request
    def has_line_type?(line_type)
      return true if @lines.length == 1 && @lines[0][:line_type] == line_type.to_sym
      
      @lines.detect { |l| l[:line_type] == line_type.to_sym }
    end
    
    alias :=~ :has_line_type?
    
    # Returns the value that was captured for the "field" of this request.
    # This function will return the first value that was captured if the field
    # was captured in multiple lines
    def first(field)
      @attributes[field]
    end
    
    alias :[] :first
    
    # Returns an array of all the "field" values that were captured for this request
    def every(field)
      @lines.inject([]) { |result, fields| result << fields[field] if fields.has_key?(field); result }
    end    
    
    # Returns true if this request does not yet contain any parsed lines. This should only occur 
    # during parsing. An empty request should never be sent to the aggregators
    def empty?
      @lines.length == 0
    end
    
    # Checks whether this request is completed. A completed request contains both a parsed header
    # line and a parsed footer line. Not that calling this function in single line mode will always 
    # return false.
    def completed?
      header_found, footer_found = false, false
      @lines.each do |line| 
        line_def = file_format.line_definitions[line[:line_type]]
        header_found = true if line_def.header
        footer_found = true if line_def.footer        
      end
      header_found && footer_found      
    end
    
    # This function is called before a Requests is yielded.
    def validate
    end
    
    # Returns the first timestamp encountered in a request. 
    def timestamp
      first(:timestamp)
    end
    
    def first_lineno
      @lines.map { |line| line[:lineno] }.reject { |v| v.nil? }.min
    end
    
    def last_lineno
      @lines.map { |line| line[:lineno] }.reject { |v| v.nil? }.max
    end
  end
end