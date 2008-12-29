# Prints usage table
puts "Usage: request-log-analyzer [LOGFILES*] <OPTIONS>"
puts
puts "Options:"
puts "  --format <format>, -f:     Uses the specified log file format. Defaults to rails."
puts "  --combined-requests, -c:   Combine the log lines that belong to the same request. "
puts "                             This improves the generated reports, but can skew results." 
puts "  --colorize, -z             Output reports in ASCII colors."
puts "  --database <filename>, -d: Creates an SQLite3 database of all the parsed request information."
puts "  --debug                    Print debug information while parsing."
puts 
puts "Examples:"
puts "  request-log-analyzer development.log"
puts "  request-log-analyzer -cz mongrel.0.log mongrel.1.log mongrel.2.log "
puts "  request-log-analyzer --format merb -d requests.db production.log"
puts
puts "To install rake tasks in your Rails application, "
puts "run the following command in your application's root directory:"
puts
puts "  request-log-analyzer install rails"
