module RequestLogAnalyzer
  module Filter
    # Base filter class used to filter input requests.
    # All filters should interit from this base.
    class Base
      
      include RequestLogAnalyzer::FileFormat::Awareness
      
      attr_reader :log_parser
      attr_reader :options
      
      # Initializer
      # <tt>format</tt> The file format
      # <tt>options</tt> Are passed to the filters.
      def initialize(format, options = {})
        @options    = options
        register_file_format(format)
      end
      
      # Initialize the filter
      def prepare
      end
      
      # Return the request if the request should be kept.
      # Return nil otherwise.
      def filter(request)
        return nil unless request
        return request
      end
    end
  end
end