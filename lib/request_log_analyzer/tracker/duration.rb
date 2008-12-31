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
  
    def report_table(amount, options = {}, &block)
      
      top_categories = @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount)
      max_cat_length = top_categories.map { |a| a[0].length }.max
      space_left = [options[:report_width] - 33, [max_cat_length + 1, options[:title].length].max].min
      
      puts
      puts "%-#{space_left+1}s┃    Hits ┃      Sum. |      Avg." % [options[:title][0...space_left]] 
      puts green('━' * options[:report_width], options[:color])
          
      top_categories.each do |(cat, info)|
        hits  = info[:count]
        total = "%0.02f" % info[:total_duration]
        avg   = "%0.02f" % (info[:total_duration] / info[:count])
        puts "%-#{space_left+1}s┃%8d ┃%9ss ┃%9ss" % [cat[0...space_left], hits, total, avg]
      end
    end
  
    def report(report_width = 80, color = false)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:total, :average]
      options[:top]    ||= 20
    
    
      options[:report].each do |report|
        case report
        when :average
          report_table(options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time", :color => color, :report_width => report_width) { |request| request[:total_duration] / request[:count] }  
        when :total
          report_table(options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time", :color => color, :report_width => report_width) { |request| request[:total_duration] }
        when :hits
          report_table(options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits", :color => color, :report_width => report_width) { |request| request[:count] }
        else
          puts "Unknown duration report specified"
        end
      end
    end      
  end
end