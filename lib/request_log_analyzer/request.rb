module RequestLogAnalyzer
  
  # The Request class represents a parsed request from the log file. 
  # Instances are created by the LogParser and are passed to the different aggregators, so they
  # can do their aggregating work. 
  #
  # Note that RequestLogAnalyzer can run in two modes:
  # - Single line mode: every parsed line is regarded as a request. Request::single_line? will 
  #   return true in this case
  # - Combined requests mode: lines that belong together are grouped into one request.
  #   Request#combined? will return true in this case.
  #
  # This class provides several methods to access the data that was parsed from the log files.
  # Request#first(field_name) returns the first (only) value corresponding to the given field
  # Request#every(field_name) returns all values corresponding to the given field name as array.
  class Request
  
    include RequestLogAnalyzer::FileFormat
  
    attr_reader :lines
    
    # Initializes a new Request object. 
    # It will apply the the provided FileFormat module to this instance.
    def initialize(file_format)
      @lines = []
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
    def << (request_info_hash)
      @lines << request_info_hash
    end
    
    # Checks whether the given line type was parsed from the log file for this request
    def has_line_type?(line_type)
      @lines.detect { |l| l[:line_type] == line_type.to_sym }
    end
    
    alias :=~ :has_line_type?
    
    # Returns the value that was captured for the "field" of this request.
    # This function will return the first value that was captured if the field
    # was captured in multiple lines for a combined request.
    def first(field)
      @lines.detect { |fields| fields.has_key?(field) }[field] rescue nil
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
    
    # Checks whether this request contains exactly one line. This means that RequestLogAnalyzer
    # is running in single_line mode.
    def single_line?
      @lines.length == 1
    end
    
    # Checks whether this request contains more than one line. This means that RequestLogAnalyzer
    # is runring in combined requests mode.
    def combined?
      @lines.length > 1
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
    
    # Returns the line type of the parsed line of this request.
    # This function can only be called in single line mode.
    def line_type
      raise "Not a single line request!" unless single_line?
      lines.first[:line_type]
    end
  end
end