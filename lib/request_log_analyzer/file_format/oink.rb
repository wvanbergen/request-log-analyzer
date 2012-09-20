class RequestLogAnalyzer::FileFormat::Oink < RequestLogAnalyzer::FileFormat::Rails
  # capture the PID
  HODEL3000_PROCESSING = /\[(\d+)\]: Processing ((?:\w+::)*\w+)#(\w+)(?: to (\w+))? \(for (#{ip_address}) at (#{timestamp('%Y-%m-%d %H:%M:%S')})\) \[([A-Z]+)\]/
  
  # TODO: fix me!
  line_definition :processing do |line|
    line.header = true
    line.regexp = Regexp.union(LINE_DEFINITIONS[:processing].regexp,HODEL3000_PROCESSING)
    line.captures = [   { :name => :controller, :type  => :string }, # Default Rails Processing
                        { :name => :action,     :type  => :string },
                        { :name => :format,     :type  => :string, :default => 'html' },
                        { :name => :ip,         :type  => :string },
                        { :name => :timestamp,  :type  => :timestamp },
                        { :name => :method,     :type  => :string },
                        { :name => :pid,        :type  => :integer }, # Hodel 3000 Processing w/PID
                        { :name => :controller, :type  => :string },
                        { :name => :action,     :type  => :string },
                        { :name => :format,     :type  => :string, :default => 'html' },
                        { :name => :ip,         :type  => :string },
                        { :name => :timestamp,  :type  => :timestamp },
                        { :name => :method,     :type  => :string }]
  end
  
  line_definition :memory_usage do |line|
    line.regexp   = /\[(\d+)\]: Memory usage: (\d+)/
    line.capture(:pid).as(:integer)
    line.capture(:memory).as(:traffic)
  end

  line_definition :instance_type_counter do |line|
    line.regexp = /\[(\d+)\]: Instantiation Breakdown: (.*)$/
    line.capture(:pid).as(:integer) 
    line.capture(:instance_counts).as(:pipe_separated_counts)
  end
  
  report(:append) do |analyze|
    analyze.traffic :memory_diff, :category => REQUEST_CATEGORIZER, :title => "Largest Memory Increases", :line_type => :memory_usage
  end
  
  # Keep a record of PIDs and their memory usage when validating requests.
  def pids
    @pids ||= {}
  end

  class Request < RequestLogAnalyzer::FileFormat::Rails::Request
    # Overrides the #validate method to handle PID updating.
    def validate
      update_pids
      super
    end
   
    # Accessor for memory information associated with the specified request PID. If no memory exists
    # for this request's :pid, the memory tracking is initialized.
    def pid_memory
      file_format.pids[self[:pid]] ||= { :last_memory_reading => -1, :current_memory_reading => -1 }
    end
    
    # Calculates :memory_diff for each request based on the last completed request that was not a failure.
    def update_pids
      # memory isn't recorded with exceptions. need to set #last_memory_reading+ to -1 as
      # the memory used could have changed. for the next request the memory change will not be recorded.
      #
      # NOTE - the failure regex was not matching with a Rails Development log file.
      if has_line_type?(:failure) and processing = has_line_type?(:processing)
        pid_memory[:last_memory_reading] = -1
      elsif mem_line = has_line_type?(:memory_usage)
        memory_reading = mem_line[:memory]
        pid_memory[:current_memory_reading] = memory_reading
        # calcuate the change in memory
        unless pid_memory[:current_memory_reading] == -1 || pid_memory[:last_memory_reading] == -1
          # logged as kB, need to convert to bytes for the :traffic Tracker
          memory_diff = (pid_memory[:current_memory_reading] - pid_memory[:last_memory_reading])*1024
          if memory_diff > 0
            self.attributes[:memory_diff] = memory_diff
          end # if memory_diff > 0
        end # unless
        
        pid_memory[:last_memory_reading] = pid_memory[:current_memory_reading]
        pid_memory[:current_memory_reading] = -1
      end # if mem_line
      return true
    end

    def convert_pipe_separated_counts(value, capture_definition)
      count_strings = value.split(' | ')
      count_arrays = count_strings.map do |count_string|
        if count_string =~ /^(\w+): (\d+)/
          [$1, $2.to_i]
        end
      end

      Hash[count_arrays]
    end
  
  end # class Request
end
