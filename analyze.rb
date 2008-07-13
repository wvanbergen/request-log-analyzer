#!/usr/bin/ruby
require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/summarizer'

raise "Please provide a path to a rails log file" if $*.length == 0

parser = RailsAnalyzer::LogParser.new($*.first)
summarizer = RailsAnalyzer::Summarizer.new

def request_hasher(request)
  if request[:url]
    url = request[:url].split('?').first.gsub(/\/\d+/, '/:id')
    url.split(/^http:\/\/[A-z0-9\.-]+/).last
  elsif request[:controller] && request[:action]
    "#{request[:controller]}##{request[:action]}"
  else
    raise 'Cannot hash this request! ' + request.inspect
  end
end

parser.each_completed_request do |request|
  summarizer.group(request)  { |r| request_hasher(r) }
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
puts "Top 10 most requested actions"
puts "=============================================================="
summarizer.sort_actions_by(:count).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(30)}: %d requests" % [a[1][:count]]
end

puts
puts "Top 10 actions by time - cumulative"
puts "=============================================================="
summarizer.sort_actions_by(:total_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(30)}: %10.03fs [%d requests]" % [a[1][:total_time], a[1][:count]]
end

puts
puts "Top 10 actions by time - per request mean"
puts "=============================================================="
summarizer.sort_actions_by(:mean_time, 100).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(30)}: %10.03fs [%d requests]" % [a[1][:mean_time], a[1][:count]]
end


puts
puts "Top 10 worst DB offenders - cumulative time"
puts "=============================================================="
summarizer.sort_actions_by(:total_db_time).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(30)}: %10.03fs [%d requests]" % [a[1][:total_db_time], a[1][:count]]
end

puts
puts "Top 10 worst DB offenders - mean time"
puts "=============================================================="
summarizer.sort_actions_by(:mean_time, 100).reverse[0, 10].each do |a|
  puts "#{a[0].ljust(30)}: %10.03fs [%d requests]" % [a[1][:mean_time], a[1][:count]]
end