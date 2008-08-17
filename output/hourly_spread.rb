# Draws a graph containing the average amound of requests per hour per day
if $summarizer.request_time_graph?

  max_request_graph = $summarizer.request_time_graph.max / $summarizer.duration
  deviation         = max_request_graph / 20
  color_cutoff      = 15
  
  puts
  puts "Requests graph - per hour"
  puts green("========================================================================")
  
  (0..23).each do |a|
    requests      = $summarizer.request_time_graph[a] / $summarizer.duration
    display_chars = requests / deviation
    
    if display_chars >= color_cutoff
      display_chars_string = green(' ΢' * color_cutoff) + red(' ΢' * (display_chars - color_cutoff))
    else
      display_chars_string = green(' ΢' * display_chars)
    end
    
    puts "#{a.to_s.rjust(10)}:00 - #{('[' + requests.to_s + ' req.]').ljust(15)} : #{display_chars_string}"
  end
else
  puts
  puts "Hourly spread not available"
end