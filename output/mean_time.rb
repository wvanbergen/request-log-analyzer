# Prints  table sorted by the duration of the requests
puts
puts "Top #{@amount} actions by time - per request mean"
puts green("========================================================================")

print_table(@summarizer, :mean_time, @amount)
