# Prints a table showing the slowest renderes
amount = $arguments[:amount] || 10
puts
puts "Top #{amount} slow renderers - mean time"
puts green("========================================================================")
print_table($summarizer, :mean_rendering_time, amount)

