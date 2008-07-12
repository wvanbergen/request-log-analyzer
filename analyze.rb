#!/usr/bin/ruby
require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/summarizer'

raise "Please provide a path to a rails log file" if $*.length == 0

parser = RailsAnalyzer::LogParser.new($*.first)
summarizer = RailsAnalyzer::Summarizer.new

parser.each_completed_request do |request|
  summarizer.summarize(request)
end



puts "Rails log analyzer, by Willem 'Gadget' van Bergen"
puts "=============================================================="
#puts "Parsing problems: open/close mismatch: #{parser.open_errors}/#{parser.close_errors}"
puts "Successfully analyzed #{summarizer.request_count} requests from log file"
puts
#puts "Timestamp first request: #{summarizer.first_request_at}"
#puts "Timestamp last request:  #{summarizer.last_request_at}"
#puts "Total time analyzed: #{summarizer.duration} days"
puts
puts "Top 10 actions by total time"
puts "=============================================================="
summarizer.sort_actions_by(:total_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(40)}: %10.03fs" % [a[1][:total_time]]
end

puts
puts "Top 10 actions by mean time"
puts "=============================================================="
summarizer.sort_actions_by(:mean_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(40)}: %10.03fs" % [a[1][:mean_time]]
end


puts
puts "Top 10 worst DB offenders"
puts "=============================================================="
summarizer.sort_actions_by(:total_db_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(40)}: %10.03fs" % [a[1][:total_db_time]]
end

puts
puts "Top 10 worst rendering offenders"
puts "=============================================================="
summarizer.sort_actions_by(:total_rendering_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(40)}: %10.03fs" % [a[1][:total_rendering_time]]
end