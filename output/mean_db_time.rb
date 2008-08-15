amount = $arguments[:amount] || 10
puts
puts "Top #{amount} worst DB offenders - mean time"
puts "========================================================================"
print_table($summarizer, :mean_db_time, amount)

