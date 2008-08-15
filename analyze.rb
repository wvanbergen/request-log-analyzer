#!/usr/bin/ruby
require 'lib/command_line/arguments'
require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/summarizer'

puts "Rails log analyzer, by Willem van Bergen and Bart ten Brinke"
puts 

def request_hasher(request)
  if request[:url]
    url = request[:url].downcase.split(/^http[s]?:\/\/[A-z0-9\.-]+/).last.split('?').first # only the relevant URL part
    url << '/' if url[-1] != '/'[0] && url.length > 1 # pad a trailing slash for consistency

    url.gsub!(/\/\d+-\d+-\d+/, '/:date') # Combine all (year-month-day) queries
    url.gsub!(/\/\d+-\d+/, '/:month') # Combine all date (year-month) queries
    url.gsub!(/\/\d+/, '/:id') # replace identifiers in URLs
        
    return url
  elsif request[:controller] && request[:action]
    return "#{request[:controller]}##{request[:action]}"
  else
    raise 'Cannot hash this request! ' + request.inspect
  end
end

begin
  
  $arguments = CommandLine::Arguments.parse do |command_line|
    command_line.switch(:guess_database_time, :g)
    command_line.switch(:fast, :f)
    command_line.required_files = 1
  end
  
rescue CommandLine::Error => e
  puts "ARGUMENT ERROR: " + e.message
  puts
  puts "Usage: ruby parsetodb.rb [LOGFILES*] <OPTIONS>"
  puts
  puts "Options:"
  puts "  --fast, -t:                 Only use completed requests"
  puts "  --guess-database-time, -g:  Guesses the database duration of requests"      
  puts
  puts "Examples:"
  puts "  ./analyze.rb development.log"
  puts "  ./analyze.rb mongrel.0.log mongrel.1.log mongrel.2.log -g -f"
  puts 
   
  exit(0) 
end

summarizer = RailsAnalyzer::Summarizer.new(:calculate_database => $arguments[:guess_database_time])
summarizer.blocker_duration = 1.0

line_types = $arguments[:fast] ? [:completed] : [:started, :completed]

$arguments.files.each do |log_file|
  puts "Processing #{line_types.join(', ')} log lines from #{log_file}..."
  parser = RailsAnalyzer::LogParser.new(log_file).each(*line_types) do |request|
    summarizer.group(request)  { |r| request_hasher(r) }
  end
end


puts "========================================================================"
#puts "Parsing problems: open/close mismatch: #{parser.open_errors}/#{parser.close_errors}" if parser.open_errors && parser.close_errors
#puts "Successfully analyzed #{summarizer.request_count} requests from log file"
#puts
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