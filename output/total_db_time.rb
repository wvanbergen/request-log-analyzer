# Prints a list of the actions that spend most of their time waiting for database results.
amount = $arguments[:amount] || 10
puts
puts "Top #{amount} worst DB offenders - cumulative time"
puts green("========================================================================")
print_table($summarizer, :total_db_time, amount)
