namespace :rla do
  desc "Analyze the Rails log file using the request-log-analyzer gem."
    task :report  => :environment do
      puts "Analyzing the Rails log file using the request-log-analyzer gem."
      puts "Environment: #{RAILS_ENV}"
      puts "Logfile: #{Rails.configuration.log_path}"
      puts ""
      `request-log-analyzer #{Rails.configuration.log_path}`
  end

  namespace :report do
    desc "Analyze the Rails log file using the request-log-analyzer gem and output an HTML file."
      task :html  => :environment do
        output_file = Rails.configuration.log_path + "/rla.html"

        puts "Analyzing the Rails log file using the request-log-analyzer gem."
        puts "Environment: #{RAILS_ENV}"
        puts "Logfile: #{Rails.configuration.log_path}"
        puts "Output: #{Rails.configuration.log_path}"
        puts ""
        `request-log-analyzer #{Rails.configuration.log_path} --output HTML > #{output_file}`
        puts ""
        puts "A html report was generated here:"
        puts output_file
        puts ""
      end
    end
  end
    
end
