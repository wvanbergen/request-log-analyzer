# Prints a table sorted by the highest database times.
amount = $arguments[:amount] || 10
puts
puts "Top #{amount} worst DB offenders - mean time"
puts green("========================================================================")
print_table($summarizer, :mean_db_time, amount)

