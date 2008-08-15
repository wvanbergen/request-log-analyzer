amount = $arguments[:amount] || 10
puts
puts "Top #{amount} actions by time - cumulative"
puts "========================================================================"
print_table($summarizer, :total_time, amount)
