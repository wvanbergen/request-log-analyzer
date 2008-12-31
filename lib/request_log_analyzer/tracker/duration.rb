module RequestLogAnalyzer::Tracker

  class Duration < RequestLogAnalyzer::Tracker::Base
  
    attr_reader :categories
  
    def prepare
      raise "No duration field set up for category tracker #{self.inspect}" unless options[:duration]
      raise "No categorizer set up for duration tracker #{self.inspect}" unless options[:category]
    
      @categories = {}
    end
  
    def update(request)
      category = options[:category].respond_to?(:call) ? options[:category].call(request) : request[options[:category]]
      duration = options[:duration].respond_to?(:call) ? options[:duration].call(request) : request[options[:duration]]
    
      if !duration.nil? && !category.nil?
        @categories[category] ||= {:count => 0, :total_duration => 0.0}
        @categories[category][:count] += 1
        @categories[category][:total_duration] += duration
      end
    end
  
    def report_top(amount, options = {}, &block)
      if options[:title]
        puts
        puts "#{options[:title]}" 
        puts green('━' * options[:report_width], options[:color])
      end
    
      @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount).each do |(cat, info)|
        hits  = info[:count]
        total = "%-2.01f" % info[:total_duration]
        avg   = green(("(%-2.01fs avg)" % (info[:total_duration] / info[:count])) , options[:color])
      
        puts "%-50s: %6d hits - %6ss total %s" % [cat[0...49], hits, total, avg]
      end
    end
  
    def report(report_width = 80, color = false)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:total, :average]
      options[:top]    ||= 20
    
    
      options[:report].each do |report|
        case report
        when :average
          report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time:", :color => color, :report_width => report_width) { |request| request[:total_duration] / request[:count] }  
        when :total
          report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time:", :color => color, :report_width => report_width) { |request| request[:total_duration] }
        when :hits
          report_top(options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits:", :color => color, :report_width => report_width) { |request| request[:count] }
        else
          puts "Unknown duration report specified"
        end
      end
    end      
  end
end