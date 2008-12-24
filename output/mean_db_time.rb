# Prints a table sorted by the highest database times.
puts
puts "Top #{amount} worst DB offenders - mean time"
puts green("========================================================================")
print_table(@summarizer, :mean_db_time, @amount)

