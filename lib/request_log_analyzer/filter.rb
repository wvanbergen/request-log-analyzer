module RequestLogAnalyzer::Filter

  autoload :Field,     'request_log_analyzer/filter/field'
  autoload :Timespan,  'request_log_analyzer/filter/timespan'
  autoload :Anonymize, 'request_log_analyzer/filter/anonymize'

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