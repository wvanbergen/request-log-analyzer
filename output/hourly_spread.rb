if $summarizer.request_time_graph?
  max_request_graph = $summarizer.request_time_graph.max
  deviation = max_request_graph / 20
  puts
  puts "Requests graph requests - per hour"
  puts "========================================================================"
  (0..23).each do |a|
    times = $summarizer.request_time_graph[a]
    display_chars = times / deviation
   puts "#{a.to_s.rjust(10)}:00 - #{times.to_s.ljust(20)} : #{'X' * display_chars}"
  end  
else
  puts
  puts "Hourly spread not available"
end