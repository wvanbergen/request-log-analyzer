namespace :rla do
  desc "Analyze the Rails log file using the request-log-analyzer gem."
  task :report  => :environment do
    rails_env  = defined?(RAILS_ENV) ? RAILS_ENV : Rails.env
    rails_root = defined?(RAILS_ROOT) ? RAILS_ROOT : Rails.root
    rails_version = Rails.version.split(".").first.to_i

    log_file   = defined?(Rails.configuration.log_path) ? Rails.configuration.log_path : Rails.configuration.paths["log"].first
    log_format = rails_version > 2 ? "rails3" : "rails"

    puts "Analyzing the Rails log file using the request-log-analyzer gem."
    puts "  Environment: #{rails_env}"
    puts "  Logfile: #{log_file}"
    puts ""

    IO.popen("request-log-analyzer #{log_file} --format #{log_format}") { |io| $stdout << io.read }
  end

  namespace :report do
    desc "Analyze the Rails log file using the request-log-analyzer gem and output an HTML file."
    task :html  => :environment do
      rails_env  = defined?(RAILS_ENV) ? RAILS_ENV : Rails.env
      rails_root = defined?(RAILS_ROOT) ? RAILS_ROOT : Rails.root
      rails_version = Rails.version.split(".").first.to_i

      log_file   = defined?(Rails.configuration.log_path) ? Rails.configuration.log_path : Rails.configuration.paths["log"].first
      log_format = rails_version > 2 ? "rails3" : "rails"

      output_file = File.join(rails_root, 'public', 'performance.html')

      puts "Analyzing the Rails log file using the request-log-analyzer gem."
      puts "  Environment: #{rails_env}"
      puts "  Logfile: #{log_file}"
      puts "  Output: #{output_file}"
      puts ""

      IO.popen("request-log-analyzer #{log_file} --output HTML --file #{output_file} --format #{log_format}") { |io| $stdout << io.read }
    end
  end

  # Split a single logfile into multiple multiple logfiles based on PID information
  # provided in the log lines.
  #
  # Usage:
  #   rake rla:split_log FILE=logfile
  #
  # Example:
  # $> rake rla:split_log FILE=log/development.log
  # Splitting the Rails log file by pid using the request-log-analyzer gem.
  #
  # Log file was split into the following files:
  #   split_log_development.catchall.log   # <- log lines without a pid
  #   split_log_development.14634.log
  #   split_log_development.31277.log
  #   split_log_development.31279.log
  #
  # To analyze type:
  #   request-log-analyzer /log/split_log_development.*.log
  desc "Split a logfile into seperate files by PID"
  task :split do

    if ENV['FILE']
      logfile = ENV['FILE']
      if logfile.nil?
        puts "Please provide a logfile to split"
        exit(0)
      elsif !File.exist?(logfile)
        puts "the logfile name you provided can not be found"
        exit(0)
      end

      # Inline class def. Ugly, yet portable.
      class LogSplitter
        attr_reader :files_by_pid, :catchall, :filename, :rla_call_string

        # All generated files should contain this prefix to allow for easy glob file matches
        PREFIX      = 'split_log_'
        # The logfile pattern that captures the pid, this will be log format specific. Using Logging::Logger
        # we define: Logging::Layouts::Pattern(:pattern => "%d pid:%p [%c:%l] %m [%F:%L]\n")
        # PID_PATTERN = Regexp.union(/.*\[(\d+)\]\:/, /pid:(\d+)/)
        PID_PATTERN = /(?-mix:.*\[(\d+)\]\:)|(?-mix:pid:(\d+))/ #

        # Currently expects the filename to exist in the local directory for ease of implementation
        def initialize(filename_to_split)
          @filename = filename_to_split
          directory = File.dirname(@filename) + '/'
          directory = '' if @directory == './'
          basename = @filename.split('/').last.gsub('.log', '')
          @rla_call_string = "#{directory}#{PREFIX}#{basename}.*.log"

          @files_by_pid =
            Hash.new {|hash, pid_key| hash[pid_key] = File.open("#{directory}#{PREFIX}#{basename}.#{pid_key}.log", 'w') }
          @catchall = File.open("#{directory}#{PREFIX}#{basename}.catchall.log", 'w')
        end

       def split
          last_pid = nil
          File.open(filename, 'r') do |f|
            while(line = f.gets)
              outfile =
                if match_data = line.match(PID_PATTERN)
                  pid = match_data.captures[0]
                  last_pid = pid
                  files_by_pid[pid]
                elsif last_pid
                  # handle cases where a single log call results in multiple lines of output.
                  files_by_pid[last_pid]
                else
                  catchall
                end
              outfile.puts line
            end
          end
        end

        def close_files
          @files_by_pid.values.map(&:close)
          @catchall.close
        end
      end
      # End inline class def

      puts "Splitting the Rails log file by pid using the request-log-analyzer gem."

      log_splitter = LogSplitter.new(logfile)
      log_splitter.split
      log_splitter.close_files

      puts ''
      puts ''
      puts 'Log file was split into the following files:'
      puts '  ' + log_splitter.catchall.path
      log_splitter.files_by_pid.values.each {|f| puts '  ' + f.path }
      puts ''
      puts 'To analyze type:'
      puts "  request-log-analyzer #{log_splitter.rla_call_string}"
      puts ''
      puts ''
    end

  end

end
