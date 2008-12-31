module RequestLogAnalyzer
  module Filter
    class Base
      
      include RequestLogAnalyzer::FileFormat
      
      attr_reader :log_parser
      attr_reader :options
      
      def initialize(format, options = {})
        @options    = options
        register_file_format(format)
      end
      
      def prepare
      end
      
      def filter(request)
        return true
      end
    end
  end
end