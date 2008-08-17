# Prints a list ordered by the requests that took the most time in total.
amount = $arguments[:amount] || 10
puts
puts "Top #{amount} actions by time - cumulative"
puts green("========================================================================")
print_table($summarizer, :total_time, amount)
