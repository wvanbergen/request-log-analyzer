module RequestLogAnalyzer::FileFormat
  class Rails3Solr < RequestLogAnalyzer::FileFormat::Rails3
    extend_line_definition :completed do |line|
      # Completed 200 OK in 43.2ms (Views: 2.3ms | ActiveRecord: 25.0ms | Solr: 89.5ms)
      line.regexp = /Completed (\d+)? .*in (\d+(?:\.\d+)?)ms(?:[^\(]*\(Views: (\d+(?:\.\d+)?)ms(?:.* ActiveRecord: (\d+(?:\.\d+)?)ms)?(?:.* Solr: (\d+(?:\.\d+)?)ms)?.*\))?/
      line.capture(:solr).as(:duration, unit: :msec)
    end
  end
end