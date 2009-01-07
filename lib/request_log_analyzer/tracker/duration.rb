module RequestLogAnalyzer::Tracker

  # Analyze the duration of a specific attribute
  #
  # Accepts the following options:
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:title</tt> Title do be displayed above the report  
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:duration</tt> The field containing the duration in the request hash.
  # * <tt>:amount</tt> The amount of lines in the report
  #
  # The items in the update request hash are set during the creation of the Duration tracker.
  #
  # Example output:
  #  Request duration - top 20 by cumulative time   ┃    Hits ┃      Sum. |      Avg.
  #   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #  EmployeeController#show.html [GET]             ┃    4742 ┃  4922.56s ┃     1.04s
  #  EmployeeController#update.html [POST]          ┃    4647 ┃  2731.23s ┃     0.59s
  #  EmployeeController#index.html [GET]            ┃    5802 ┃  1477.32s ┃     0.25s
  #  .............
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
  
    def report_table(output = STDOUT, amount = 10, options = {}, &block)
      
      top_categories = @categories.sort { |a, b| yield(b[1]) <=> yield(a[1]) }.slice(0...amount)
      max_cat_length = top_categories.map { |a| a[0].length }.max
      space_left = [options[:report_width] - 33, [max_cat_length + 1, options[:title].length].max].min
      
      output << "\n"
      output << "%-#{space_left+1}s┃    Hits ┃      Sum. |      Avg." % [options[:title][0...space_left]] + "\n"
      output << green('━' * options[:report_width], options[:color]) + "\n"
          
      top_categories.each do |(cat, info)|
        hits  = info[:count]
        total = "%0.02f" % info[:total_duration]
        avg   = "%0.02f" % (info[:total_duration] / info[:count])
        output << "%-#{space_left+1}s┃%8d ┃%9ss ┃%9ss" % [cat[0...space_left], hits, total, avg] + "\n"
      end
    end
  
    def report(output = STDOUT, report_width = 80, color = false)

      options[:title]  ||= 'Request duration'
      options[:report] ||= [:total, :average]
      options[:top]    ||= 20
    
      options[:report].each do |report|
        case report
        when :average
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by average time", :color => color, :report_width => report_width) { |request| request[:total_duration] / request[:count] }  
        when :total
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by cumulative time", :color => color, :report_width => report_width) { |request| request[:total_duration] }
        when :hits
          report_table(output, options[:top], :title => "#{options[:title]} - top #{options[:top]} by hits", :color => color, :report_width => report_width) { |request| request[:count] }
        else
          output << "Unknown duration report specified\n"
        end
      end
    end      
  end
end