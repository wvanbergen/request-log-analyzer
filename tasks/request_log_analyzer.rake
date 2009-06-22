namespace :rla do
  desc "Analyze the Rails log file using the request-log-analyzer gem."
  task :report  => :environment do
    puts "Analyzing the Rails log file using the request-log-analyzer gem."
    puts "  Environment: #{RAILS_ENV}"
    puts "  Logfile: #{Rails.configuration.log_path}"
    puts ""
    IO.popen("request-log-analyzer #{Rails.configuration.log_path}") { |io| $stdout << io.read }
    
  end

  namespace :report do
    desc "Analyze the Rails log file using the request-log-analyzer gem and output an HTML file."
    task :html  => :environment do
      output_file = Rails.configuration.log_path + ".html"

      puts "Analyzing the Rails log file using the request-log-analyzer gem."
      puts "  Environment: #{RAILS_ENV}"
      puts "  Logfile: #{Rails.configuration.log_path}"
      puts "  Output: #{output_file}"
      puts ""
      IO.popen("request-log-analyzer #{Rails.configuration.log_path} --output HTML --file #{output_file}") { |io| $stdout << io.read }
    end
  end
    
end
