module RequestLogAnalyzer
  module Filter
    class Base
      
      include RequestLogAnalyzer::FileFormat
      
      attr_reader :log_parser
      attr_reader :options
      
      def initialize(log_parser, options = {})
        @options    = options
        @log_parser = log_parser
        register_file_format(log_parser.file_format)
      end
      
      def prepare
      end
      
      def filter(request)
        return true
      end
    end
  end
end