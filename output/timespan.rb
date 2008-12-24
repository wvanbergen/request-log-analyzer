# Prints the total timespan found in the parsed log files.
puts
puts green("========================================================================")

if @summarizer.has_timestamps?
  puts "Timestamp first request: #{@summarizer.first_request_at}"
  puts "Timestamp last request:  #{@summarizer.last_request_at}" 
  puts "Total time analyzed:     #{@summarizer.duration} days"
  puts ""
  puts "Total requests analyzed: #{@summarizer.request_count}"
end

methods_print_array = []
methods_request_count = @summarizer.methods.inject(0) { |subtotal, (k, v)| subtotal + v }
@summarizer.methods.each do |key, value|
  methods_print_array << green("%s (%0.01f%%)") % [key, (value * 100) / methods_request_count.to_f]
end
puts 'Methods: ' + methods_print_array.join(', ') + '.'
