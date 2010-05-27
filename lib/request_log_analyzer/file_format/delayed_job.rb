module RequestLogAnalyzer::FileFormat

  # The DelayedJob file format parsed log files that are created by DelayedJob.
  # By default, the log file can be found in RAILS_ROOT/log/delayed_job.log
  class DelayedJob < Base
    
    line_definition :job_lock do |line|
      line.header = true
      line.regexp = /\* \[JOB\] acquiring lock on (\S+)/
      
      line.capture(:job)
    end
    
    line_definition :job_completed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] (\S+) completed after (\d+\.\d+)/

      line.capture(:completed_job)
      line.capture(:duration).as(:duration, :unit => :sec) 
    end
    
    line_definition :job_failed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] (\S+) failed with (\S+)\: .* - (\d+) failed attempts/
      
      line.capture(:failed_job)
      line.capture(:exception)
      line.capture(:attempts).as(:integer)
    end
    
    line_definition :job_lock_failed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] failed to acquire exclusive lock for (\S+)/
      
      line.capture(:locked_job)
    end
    
    # line_definition :batch_completed do |line|
    #   line.header = true
    #   line.footer = true
    #   line.regexp = /(\d+) jobs processed at (\d+\.\d+) j\/s, (\d+) failed .../
    #
    #   line.capture(:total_amount).as(:integer)
    #   line.capture(:mean_duration).as(:duration, :unit => :sec)
    #   line.capture(:failed_amount).as(:integer)
    # end
    
    report do |analyze|
      analyze.frequency :job, :line_type => :job_completed, :title => "Completed jobs"
      analyze.frequency :job, :if => lambda { |request| request[:attempts] ==  1 }, :title => "Failed jobs"
      
      analyze.duration :duration, :category => :job, :line_type => :job_completed, :title => "Job duration"
    end
  end
end
