module RequestLogAnalyzer::Tracker

  class Timespan < RequestLogAnalyzer::Tracker::Base

    attr_reader :first, :last, :request_time_graph
  
    def prepare
      raise "No categorizer set up for category tracker #{self.inspect}" unless options[:field]
    end
              
    def update(request)
      timestamp = request[options[:field]]

      @first = timestamp if @first.nil? || timestamp < @first
      @last  = timestamp if @last.nil?  || timestamp > @last
    end
  
    def report(report_width = 80, color = false)
      if options[:title]
        puts "\n#{options[:title]}" 
        puts green('━' * options[:title].length, color)
      end
      
      puts @first.inspect
      
      first_date  = DateTime.parse(@first.to_s, '%Y%m%d%H%M%S')
      last_date   = DateTime.parse(@last.to_s, '%Y%m%d%H%M%S')
      days        = (@last && @first) ? (last_date - first_date).ceil : 1

      puts first_date.inspect

      puts "First request:        #{first_date.strftime('%Y-%m-%d %H:%M:%I')}"
      puts "Last request:         #{last_date.strftime('%Y-%m-%d %H:%M:%I')}"        
      puts "Total time analyzed:  #{days} days"
      puts ""
    end
  end
end