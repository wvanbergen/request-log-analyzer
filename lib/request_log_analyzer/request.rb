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

      # Default converter function, which converts the parsed strings to a native Ruby type
      # using the type indication in the line definition. It will use a custom connverter
      # method if one is available.
      def convert_value(value, capture_definition)
        return capture_definition[:default] if value.nil?
        custom_converter_method = :"convert_#{capture_definition[:type]}"
        send(custom_converter_method, value, capture_definition)
      end

      def convert_string(value, capture_definition);  value; end
      def convert_float(value, capture_definition);   value.to_f; end
      def convert_decimal(value, capture_definition); value.to_f; end
      def convert_int(value, capture_definition);     value.to_i; end
      def convert_integer(value, capture_definition); value.to_i; end
      def convert_sym(value, capture_definition);     value.to_sym; end
      def convert_symbol(value, capture_definition);  value.to_sym; end
      def convert_nillable_string(value, definition); value == '-' ? nil : value ; end
      
      # This function can be overridden to rewrite the path for better categorization in the
      # reports.
      def convert_path(value, definition)
        value
      end

      # Converts :eval field, which should evaluate to a hash.
      def convert_eval(value, capture_definition)
        eval(sanitize_parameters(value)).inject({}) { |h, (k, v)| h[k.to_sym] = v; h}
			# Wide range of errors possible with wild eval. ATM we choose to crash on this.
      rescue SyntaxError 
        nil
      end

      # Removes certain string sequences which would be problematic for eval.
      # TODO remove all characters not valid in ruby symbols
      def sanitize_parameters(parameter_string)
        parameter_string.gsub(/#</, '"').gsub(/>,/, '", ').gsub(/\\0/, '')
      end

      # Slow default method to parse timestamps.
      # Reimplement this function in a file format specific Request class
      # to improve the timestamp parsing speed.
      def convert_timestamp(value, capture_definition)
        DateTime.parse(value).strftime('%Y%m%d%H%M%S').to_i
      end

      # Converts traffic fields to (whole) bytes based on the given unit.
      def convert_traffic(value, capture_definition)
        case capture_definition[:unit]
        when nil, :b, :B, :byte      then value.to_i
        when :GB, :G, :gigabyte      then (value.to_f * 1000_000_000).round
        when :GiB, :gibibyte         then (value.to_f * (2 ** 30)).round
        when :MB, :M, :megabyte      then (value.to_f * 1000_000).round
        when :MiB, :mebibyte         then (value.to_f * (2 ** 20)).round
        when :KB, :K, :kilobyte, :kB then (value.to_f * 1000).round
        when :KiB, :kibibyte         then (value.to_f * (2 ** 10)).round
        else raise "Unknown traffic unit"
        end
      end

      # Convert duration fields to float, and make sure the values are in seconds.
      def convert_duration(value, capture_definition)
        case capture_definition[:unit]
        when nil, :sec, :s     then value.to_f
        when :microsec, :musec then value.to_f / 1000000.0
        when :msec, :millisec  then value.to_f / 1000.0
        else raise "Unknown duration unit"
        end
      end
      
      # Convert an epoch to an integer
      def convert_epoch(value, capture_definition)
        Time.at(value.to_i).strftime('%Y%m%d%H%M%S').to_i
      end
    end

    # Install the default converter methods
    include Converters

    attr_reader :lines, :attributes, :file_format

    # Initializes a new Request object.
    # It will apply the the provided FileFormat module to this instance.
    def initialize(file_format, attributes = {})
      @lines       = []
      @attributes  = attributes
      @file_format = file_format
    end

    # Creates a new request that was parsed from the log with the given FileFormat. The hashes
    # that are passed to this function are added as lines to this request.
    def self.create(file_format, *hashes)
      request = self.new(file_format)
      hashes.flatten.each { |hash| request << hash }
      return request
    end

    # Adds another line to the request when it is parsed in the LogParser.
    #
    # The line should be provided as a hash with the attributes line_definition, :captures,
    # :lineno and :source set. This function is called from LogParser.
    def add_parsed_line (parsed_line)
      value_hash = parsed_line[:line_definition].convert_captured_values(parsed_line[:captures], self)
      value_hash[:line_type] = parsed_line[:line_definition].name
      value_hash[:lineno] = parsed_line[:lineno]
      value_hash[:source] = parsed_line[:source]
      value_hash[:compound] = parsed_line[:line_definition].compound
      add_line_hash(value_hash)
    end

    # Adds another line to the request using a plain hash.
    #
    # The line should be provides as a hash of the fields parsed from the line.
    def add_line_hash(value_hash)
      @lines << value_hash
      if value_hash[:compound]
        value_hash.each do |key, value|
          if value_hash[:compound].include?(key)
            @attributes[key] = [] if @attributes[key].nil?
            @attributes[key] = [@attributes[key]] unless @attributes[key].is_a?(Array)
            @attributes[key] << value
          else
            @attributes[key] = value unless key == :compound || @attributes[key]
          end
        end
      else
        @attributes = value_hash.merge(@attributes)
      end
    end

    # Adds another line to the request. This method switches automatically between
    # the add_line_hash and add_parsed_line based on the keys of the provided hash.
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
