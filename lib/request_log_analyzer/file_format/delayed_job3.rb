module RequestLogAnalyzer::FileFormat

  # The DelayedJob3 file format parsed log files that are created by DelayedJob 3.0 or higher.
  # By default, the log file can be found in RAILS_ROOT/log/delayed_job.log
  class DelayedJob3 < Base

    extend CommonRegularExpressions

    line_definition :job_completed do |line|
      line.header = true
      line.footer = true
      line.regexp = /(#{timestamp('%Y-%m-%dT%H:%M:%S%z')}): \[Worker\(\S+ host:(#{hostname_or_ip_address}) pid:(\d+)\)\] (\S+) completed after (\d+\.\d+)/
      line.capture(:timestamp).as(:timestamp)
      line.capture(:host)
      line.capture(:pid).as(:integer)
      line.capture(:job)
      line.capture(:duration).as(:duration, :unit => :sec)
    end

    line_definition :job_failed do |line|
      line.header = true
      line.footer = true
      line.regexp = /(#{timestamp('%Y-%m-%dT%H:%M:%S%z')}): \[Worker\(\S+ host:(#{hostname_or_ip_address}) pid:(\d+)\)\] (.+) - (\d+) failed attempts/
      line.capture(:timestamp).as(:timestamp)
      line.capture(:host)
      line.capture(:pid).as(:integer)
      line.capture(:job)
      line.capture(:attempts).as(:integer)
    end

    line_definition :job_deleted do |line|
      line.header = true
      line.footer = true
      line.regexp = /(#{timestamp('%Y-%m-%dT%H:%M:%S%z')}): \[Worker\(\S+ host:(#{hostname_or_ip_address}) pid:(\d+)\)\] PERMANENTLY removing (\S+) because of (\d+) consecutive failures./
      line.capture(:timestamp).as(:timestamp)
      line.capture(:host)
      line.capture(:pid).as(:integer)
      line.capture(:job)
      line.capture(:failures).as(:integer)
    end


    report do |analyze|
      analyze.timespan
      analyze.hourly_spread

      analyze.frequency :job, :line_type => :job_completed, :title => "Completed jobs"
      analyze.frequency :job, :category => :job, :line_type => :job_failed, :title => "Failed jobs"
      analyze.frequency :failures, :category => :job, :line_type => :job_deleted, :title => "Deleted jobs"
      analyze.duration :duration, :category => :job, :line_type => :job_completed, :title => "Job duration"
    end
  end
end
