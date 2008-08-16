amount = $arguments[:amount] || 10
puts
puts "Top #{amount} most requested actions"
puts green("========================================================================")
print_table($summarizer, :count, amount)