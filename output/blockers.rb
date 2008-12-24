# Print requests that took more than a second to complete, sorted by their frequency.
puts
puts "Mongrel process blockers (> #{@summarizer.blocker_duration} seconds)"
puts green("========================================================================")

@summarizer.sort_blockers_by(:count).reverse[0, @amount].each do |a|
 puts "%-50s: %10.03fs [#{green("%d requests")}]" % [a[0], a[1][:total_time], a[1][:count]]
end

