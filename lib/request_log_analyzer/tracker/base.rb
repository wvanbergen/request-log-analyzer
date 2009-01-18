module RequestLogAnalyzer
  module Tracker
   
    # Base tracker. All other trackers inherit from this class
    #
    # Accepts the following options:
    # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
    # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
    # * <tt>:output</tt> Direct output here (defaults to STDOUT)
    #
    # For example :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }
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
      
      def report(output)
        output << self.inspect
        output << "\n"  
      end
           
    end 
  end
end