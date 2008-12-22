namespace :rails do
  desc "Analyze a Rails log file" 
    task :analyze_log  => :environment do
      puts "Environment: #{ENV}"
      puts "#{Rails.configuration.log_path}"
      puts ""
    
      `request-log-analyzer #{Rails.configuration.log_path} -z`
  end
end