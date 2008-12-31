module RequestLogAnalyzer
  module Tracker
   
    class Base

      attr_reader :options
      
      def initialize(options ={})
        @options = options
      end
        
      def prepare
      end
      
      def update(request)
      end
      
      def finalize
      end
      
      def should_update?(request)
        return false if options[:line_type] && !request.has_line_type?(options[:line_type])
        
        if options[:if].kind_of?(Symbol)
          return false unless request[options[:if]]
        elsif options[:if].respond_to?(:call)
          return false unless options[:if].call(request)
        end
        
        if options[:unless].kind_of?(Symbol)
          return false if request[options[:unless]]
        elsif options[:unless].respond_to?(:call)
          return false if options[:unless].call(request)
        end        
        
        return true
      end
      
      def report(report_width = 80, color = false)
        puts self.inspect
        puts        
      end
           
    end 
  end
end