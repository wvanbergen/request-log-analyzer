#!/usr/bin/ruby

require 'lib/rails_analyzer/log_parser'
require 'lib/rails_analyzer/record_inserter'
require 'lib/command_line/arguments'

puts "Rails log parser, by Willem van Bergen and Bart ten Brinke"
puts 

begin
  
  $arguments = CommandLine::Arguments.parse do |command_line|
    command_line.switch(:guess_database_time, :g)
    command_line.switch(:reset_database, :r)
    command_line.flag(:database, :alias => :d, :required => false)
    command_line.required_files = 1
  end
  
rescue CommandLine::Error => e
  puts "ARGUMENT ERROR: " + e.message
  puts
  puts "Usage: ruby parsetodb.rb [LOGFILES*] <OPTIONS>"
  puts
  puts "Options:"
  puts "  --database, -t:             The database file to use"
  puts "  --reset-database, -r:       Resets the database before inserting new records"
  puts "  --guess-database-time, -g:  Guesses the database duration of requests"      
  puts
  puts "Examples:"
  puts "  ./parsetodb.rb development.log"
  puts "  ./parsetodb.rb mongrel.0.log mongrel.1.log mongrel.2.log -g -d mongrel.db"  
  puts 
   
  exit(0) 
end

log_files  = $arguments.files
db_file    = $arguments[:database] || log_files.first + '.db'

if $arguments[:reset_database] && File.exist?(db_file) 
  File.delete(db_file) 
  puts "Database file cleared."
end

records_inserted = 0 
inserter = RailsAnalyzer::RecordInserter.insert_batch_into(db_file) do |db|
  log_files.each do |log_file|
    puts "Processing all log lines from #{log_file}..."
    parser = RailsAnalyzer::LogParser.new(log_file)
    
    parser.each do |request| 
      db.insert(request) 
      records_inserted += 1
    end
  end
  
  if $arguments[:guess_database_time]
    puts "Calculating database times..."
    db.calculate_db_durations! 
  end
end

started   = inserter.count(:started)
completed = inserter.count(:completed)
failed    = inserter.count(:failed)

puts 
puts "Inserted #{records_inserted} records from #{log_files.length} files."
puts
puts "Requests started: #{started}"
puts "Requests completed: #{completed}"
puts "Requests failed: #{failed}"