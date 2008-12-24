# Prints a list of the actions that spend most of their time waiting for database results.
puts
puts "Top #{@amount} worst DB offenders - cumulative time"
puts green("========================================================================")
print_table(@summarizer, :total_db_time, @amount)
