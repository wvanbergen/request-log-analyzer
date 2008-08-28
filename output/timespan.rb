# Prints the total timespan found in the parsed log files.
puts
puts green("========================================================================")

if $summarizer.has_timestamps?
  puts "Timestamp first request: #{$summarizer.first_request_at}"
  puts "Timestamp last request:  #{$summarizer.last_request_at}" 
  puts "Total time analyzed: #{$summarizer.duration} days"
end