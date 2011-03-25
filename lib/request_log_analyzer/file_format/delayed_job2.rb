module RequestLogAnalyzer::FileFormat

  # The DelayedJob2 file format parsed log files that are created by DelayedJob 2.0.
  # By default, the log file can be found in RAILS_ROOT/log/delayed_job.log
  class DelayedJob2 < Base
    
    extend CommonRegularExpressions
    
    line_definition :job_lock do |line|
      line.header = true
      line.regexp = /(#{timestamp('%Y-%m-%dT%H:%M:%S%z')}): \* \[Worker\(\S+ host:(#{hostname_or_ip_address}) pid:(\d+)\)\] acquired lock on (\S+)/
      
      line.capture(:timestamp).as(:timestamp)
      line.capture(:host)
      line.capture(:pid).as(:integer)
      line.capture(:job)
    end
    
    line_definition :job_completed do |line|
      line.footer = true
      line.regexp = /(#{timestamp('%Y-%m-%dT%H:%M:%S%z')}): \* \[JOB\] \S+ host:(#{hostname_or_ip_address}) pid:(\d+) completed after (\d+\.\d+)/
      line.capture(:timestamp).as(:timestamp)
      line.capture(:host)
      line.capture(:pid).as(:integer)
      line.capture(:duration).as(:duration, :unit => :sec)
    end
    
    report do |analyze|
      analyze.timespan
      analyze.hourly_spread

      analyze.frequency :job, :line_type => :job_completed, :title => "Completed jobs"
      #analyze.frequency :job, :if => lambda { |request| request[:attempts] ==  1 }, :title => "Failed jobs"
      
      analyze.duration :duration, :category => :job, :line_type => :job_completed, :title => "Job duration"
    end
  end
end
