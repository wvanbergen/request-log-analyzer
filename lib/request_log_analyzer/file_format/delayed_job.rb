module RequestLogAnalyzer::FileFormat

  # The DelayedJob file format parsed log files that are created by DelayedJob.
  # By default, the log file can be found in RAILS_ROOT/log/delayed_job.log
  class DelayedJob < Base
    
    line_definition :job_lock do |line|
      line.header = true
      line.regexp = /\* \[JOB\] acquiring lock on (\S+)/
      line.captures << { :name => :job, :type => :string }
    end
    
    line_definition :job_completed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] (\S+) completed after (\d+\.\d+)/
      line.captures << { :name => :completed_job, :type => :string } << 
                       { :name => :duration, :type => :duration, :unit => :sec }
    end
    
    line_definition :job_failed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] (\S+) failed with (\S+)\: .* - (\d+) failed attempts/
      line.captures << { :name => :failed_job, :type => :string  } << 
                       { :name => :exception,  :type => :string  } << 
                       { :name => :attempts,   :type => :integer }
      
    end
    
    line_definition :job_lock_failed do |line|
      line.footer = true
      line.regexp = /\* \[JOB\] failed to acquire exclusive lock for (\S+)/
      line.captures << { :name => :locked_job, :type => :string }
    end
    
    # line_definition :batch_completed do |line|
    #   line.header = true
    #   line.footer = true
    #   line.regexp = /(\d+) jobs processed at (\d+\.\d+) j\/s, (\d+) failed .../
    #   line.captures << { :name => :total_amount,  :type => :integer } << 
    #                    { :name => :mean_duration, :type => :duration, :unit => :sec } <<
    #                    { :name => :failed_amount, :type => :integer }
    # end
    
    report do |analyze|
      analyze.frequency :job, :line_type => :job_completed, :title => "Completed jobs"
      analyze.frequency :job, :if => lambda { |request| request[:attempts] ==  1 }, :title => "Failed jobs"
      
      analyze.duration :duration, :category => :job, :line_type => :job_completed, :title => "Job duration"
    end
  end
end
