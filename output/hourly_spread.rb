if $summarizer.request_time_graph?

  max_request_graph = $summarizer.request_time_graph.max
  deviation         = max_request_graph / 20
  color_cutoff      = 15
  
  puts
  puts "Requests graph requests - per hour"
  puts green("========================================================================")
  
  (0..23).each do |a|
    times         = $summarizer.request_time_graph[a]
    display_chars = times / deviation
    
    display_chars_string = green(' ΢' * display_chars)    
    display_chars_string = green(' ΢' * color_cutoff) + red(' ΢' * (display_chars - color_cutoff)) if display_chars >= color_cutoff
    
    puts "#{a.to_s.rjust(10)}:00 - #{('[' + times.to_s + ' req.]').ljust(15)} : #{display_chars_string}"
  end
else
  puts
  puts "Hourly spread not available"
end