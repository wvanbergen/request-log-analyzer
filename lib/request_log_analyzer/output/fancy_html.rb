begin 
  require 'rubygems'
  require 'gchart'
rescue LoadError
  $stderr.puts "The FancyHTML output format requires the googlechart gem:"
  $stderr.puts "  (sudo) gem install googlecharts"
end

module RequestLogAnalyzer::Output
  
  class FancyHTML < HTML
    
    # Load class files if needed
    def self.const_missing(const)
      RequestLogAnalyzer::load_default_class_file(self, const)
    end
    
    def report_tracker(tracker)
      case tracker
      when RequestLogAnalyzer::Tracker::HourlySpread then report_hourly_spread(tracker)
      else tracker.report(self)
      end
    end
    
    def report_hourly_spread(tracker)
      title tracker.title
      puts tag(:img, nil, :width => '700', :height => '120', :src =>
          Gchart.sparkline(:data => tracker.hour_frequencies, :size => '700x120', :line_colors => '0077CC'))
    end
  end
end
