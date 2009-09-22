module RequestLogAnalyzer::Filter

  # Filter class loader using const_missing
  # This function will automatically load the class file based on the name of the class
  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end

  # Base filter class used to filter input requests.
  # All filters should interit from this base.
  class Base

    attr_reader :file_format, :options

    # Initializer
    # <tt>format</tt> The file format
    # <tt>options</tt> Are passed to the filters.
    def initialize(format, options = {})
      @file_format = format
      @options     = options
    end

    # Return the request if the request should be kept.
    # Return nil otherwise.
    def filter(request)
      request
    end
  end

end