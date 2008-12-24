# Prints a table sorted by the most frequently requested actions
puts
puts "Top #{amount} most requested actions"
puts green("========================================================================")
print_table(@summarizer, :count, @amount)