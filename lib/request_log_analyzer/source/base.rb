module RequestLogAnalyzer::Source
  class Base
    
    include RequestLogAnalyzer::FileFormat::Awareness

    # A hash of options
    attr_reader :options

    # The current Request object that is being parsed
    attr_reader :current_request

    # The total number of parsed lines
    attr_reader :parsed_lines

    # The total number of parsed requests.
    attr_reader :parsed_requests

    # The number of skipped lines because of warnings
    attr_reader :skipped_lines

    # Base source class used to filter input requests.

    # Initializer
    # <tt>format</tt> The file format
    # <tt>options</tt> Are passed to the filters.
    def initialize(format, options = {})
      @options    = options
      register_file_format(format)
    end
    
    def prepare
    end
    
    def requests(&block)
      return true
    end

    def finalize
    end

  end
end