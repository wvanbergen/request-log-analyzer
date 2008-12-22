namespace :log do
  desc "Analyze the Rails log file using the request-log-analyzer gem." 
    task :analyze  => :environment do
      puts "Analyzing the Rails log file using the request-log-analyzer gem."
      puts "Environment: #{RAILS_ENV}"
      puts "Logfile: #{Rails.configuration.log_path}"
      puts ""
      `request-log-analyzer #{Rails.configuration.log_path} -z`
  end
end