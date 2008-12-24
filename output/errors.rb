# Print errors that occured often
puts
puts "Errors"
puts green("========================================================================")
@summarizer.sort_errors_by(:count).reverse[0, @amount].each do |a|
  puts "%s: [#{green("%d requests")}]" % [a[0] + 'Error', a[1][:count]]
  puts blue(' -> ' + (a[1][:exception_strings].invert[ a[1][:exception_strings].values.max ])[0..79])
end
