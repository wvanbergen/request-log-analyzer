amount = $arguments[:amount] || 10
puts
puts "Top #{amount} actions by time - per request mean"
puts green("========================================================================")

print_table($summarizer, :mean_time, amount)
