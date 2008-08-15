#!/usr/bin/ruby

require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/record_inserter'

puts 
puts "Rails log parser, by Willem van Bergen and Bart ten Brinke"
puts 

# Parse attributes
if $*.length < 1
  puts ""
  puts "Usage: ruby parsetodb.rb [LOGFILE] [DATABASEFILE]"
  puts "Example: ruby parsetodb.rb mongrel.log"
  puts ""
  exit(0)
end

log_file = $*[0]
db_file  = $*[1] || log_file + '.db'

parser = RailsAnalyzer::LogParser.new(log_file)
db     = RailsAnalyzer::RecordInserter.new(db_file)

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


puts "Processing all log lines from #{log_file}."
db.insert_batch do
  parser.each_request { |request| db.insert(request) }
end
