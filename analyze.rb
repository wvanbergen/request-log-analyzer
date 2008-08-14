#!/usr/bin/ruby
require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/summarizer'

puts 
puts "Rails log analyzer, by Willem 'Gadget' van Bergen / Bart ten Brinke"
puts 

# Parse attributes
if $*.length == 0
  puts ""
  puts "Usage: ruby analyze.rb [FILE] [OPTION]"
  puts "Analyze the given log FILE with the given OPTION"
  puts "Example: ruby analyze.rb mongrel.log"
  puts ""
  puts "Options:"
  puts " -g, --guess-database-time     Guess database times if they are not explicitly logged."
  puts " -f, --fast                    Only parse 'Completed' log lines (displays less information)."
  puts ""
  return 0
end

fast_parsing = $*.include?('-f') || $*.include?('--fast')
parser = RailsAnalyzer::LogParser.new($*.first)
summarizer = RailsAnalyzer::Summarizer.new
summarizer.blocker_duration = 1.0

def request_hasher(request)
  colliding_controllers = ['weblog', 'apidoc', 'logout']
  
  if request[:url]
    url = request[:url].downcase.split(/^http[s]?:\/\/[A-z0-9\.-]+/).last.split('?').first # only the relevant URL part
    url << '/' if url[-1] != '/'[0] && url.length > 1 # pad a trailing slash for consistency

    url.gsub!(/\/\d+-\d+-\d+/, '/:date') # Combine all (year-month-day) queries
    url.gsub!(/\/\d+-\d+/, '/:month') # Combine all date (year-month) queries
    url.gsub!(/\/\d+/, '/:id') # replace identifiers in URLs
    
    # recognize hashes in floorplanner_current
    #url.gsub!(/^\/([A-z0-9]{6})\//) { |c| colliding_controllers.include?($1) ? "/#{$1}/" : '/:hash/' }
    
    return url
  elsif request[:controller] && request[:action]
    return "#{request[:controller]}##{request[:action]}"
  else
    raise 'Cannot hash this request! ' + request.inspect
  end
end

if fast_parsing
  puts "Processing 'Completed' log lines from #{$*.first}."
  parser.each_completed_request do |request|
    summarizer.group(request)  { |r| request_hasher(r) }
  end
else
  puts "Processing all log lines from #{$*.first}."
  parser.each_request do |request|
    summarizer.group(request)  { |r| request_hasher(r) }
  end
end


puts "========================================================================"
puts "Parsing problems: open/close mismatch: #{parser.open_errors}/#{parser.close_errors}" if parser.open_errors && parser.close_errors
puts "Successfully analyzed #{summarizer.request_count} requests from log file"
puts
puts "Timestamp first request: #{summarizer.first_request_at}" if summarizer.first_request_at
puts "Timestamp last request:  #{summarizer.last_request_at}" if summarizer.last_request_at
puts "Total time analyzed: #{summarizer.duration} days" if summarizer.duration


puts
puts "Top 10 most requested actions"
puts "========================================================================"
summarizer.sort_actions_by(:count).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %d requests" % [a[1][:count]]
end

puts
puts "Top 10 actions by time - cumulative"
puts "========================================================================"
summarizer.sort_actions_by(:total_time).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %10.03fs [%d requests]" % [a[1][:total_time], a[1][:count]]
end

puts
puts "Top 10 actions by time - per request mean"
puts "========================================================================"
summarizer.sort_actions_by(:mean_time, 100).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %10.03fs [%d requests]" % [a[1][:mean_time], a[1][:count]]
end

puts
puts "Top 10 worst DB offenders - cumulative time"
puts "========================================================================"
summarizer.sort_actions_by(:total_db_time).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %10.03fs [%d requests]" % [a[1][:total_db_time], a[1][:count]]
end

puts
puts "Top 10 worst DB offenders - mean time"
puts "========================================================================"
summarizer.sort_actions_by(:mean_time, 100).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %10.03fs [%d requests]" % [a[1][:mean_time], a[1][:count]]
end

puts
puts "Mongrel process blockers (> #{summarizer.blocker_duration} seconds) - frequency"
puts "========================================================================"
summarizer.sort_blockers_by(:count).reverse[0, 20].each do |a|
  puts "#{a[0].ljust(50)}: %10.03fs [%d requests]" % [a[1][:total_time], a[1][:count]]
end

if summarizer.request_time_graph?
  max_request_graph = summarizer.request_time_graph.max
  deviation = max_request_graph / 20
  puts
  puts "Requests graph requests - per hour"
  puts "========================================================================"
  (0..23).each do |a|
    times = summarizer.request_time_graph[a]
    display_chars = times / deviation
    puts "#{a.to_s.rjust(10)}:00 - #{times.to_s.ljust(20)} : #{'X' * display_chars}"
  end  
end