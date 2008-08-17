# Print requests that took more than a second to complete, sorted by their frequency.
amount = $arguments[:amount] || 10
puts
puts "Mongrel process blockers (> #{$summarizer.blocker_duration} seconds) - frequency"
puts green("========================================================================")
$summarizer.sort_blockers_by(:count).reverse[0, amount.to_i].each do |a|
 puts "#{a[0].ljust(50)}: %10.03fs [#{green("%d requests")}]" % [a[1][:total_time], a[1][:count]]
end

