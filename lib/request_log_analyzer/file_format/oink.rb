class RequestLogAnalyzer::FileFormat::Oink < RequestLogAnalyzer::FileFormat::Rails
  # capture the PID
  HODEL3000_PROCESSING = /\[(\d+)\]: Processing ((?:\w+::)*\w+)#(\w+)(?: to (\w+))? \(for (#{ip_address}) at (#{timestamp('%Y-%m-%d %H:%M:%S')})\) \[([A-Z]+)\]/
  
  LINE_DEFINITIONS[:processing] = RequestLogAnalyzer::LineDefinition.new(:processing, :header => true,
          :teaser   => /Processing /,
          :regexp   => Regexp.union(LINE_DEFINITIONS[:processing].regexp,HODEL3000_PROCESSING),
          :captures => [{ :name => :controller, :type  => :string }, # Default Rails Processing
                        { :name => :action,     :type  => :string },
                        { :name => :format,     :type  => :string, :default => 'html' },
                        { :name => :ip,         :type  => :string },
                        { :name => :timestamp,  :type  => :timestamp },
                        { :name => :method,     :type  => :string },
                        { :name => :pid, :type => :integer },        # Hodel 3000 Processing w/PID
                        { :name => :controller, :type  => :string },
                        { :name => :action,     :type  => :string },
                        { :name => :format,     :type  => :string, :default => 'html' },
                        { :name => :ip,         :type  => :string },
                        { :name => :timestamp,  :type  => :timestamp },
                        { :name => :method,     :type  => :string }])
  
  # capture the memory usage
  LINE_DEFINITIONS[:memory_usage] = RequestLogAnalyzer::LineDefinition.new(:memory_usage,
   :regexp   => /\[(\d+)\]: Memory usage: (\d+) /,
   :captures => [{ :name => :pid, :type => :integer },{ :name => :memory, :type => :traffic }])
  
  # capture :memory usage in all line collections
  LINE_COLLECTIONS.each { |k,v| LINE_COLLECTIONS[k] << :memory_usage }
  
  report(:append) do |analyze|
      analyze.traffic :memory_diff, :category => REQUEST_CATEGORIZER, :title => "Largest Memory Increases", :line_type => :memory_usage
  end
  
  # Keep a record of PIDs and their memory usage when validating requests.
  def pids
    @pids ||= {}
  end
  
  class Request
   # Overrides the #validate method to handle PID updating.
   def validate
     update_pids
     super
   end
    
   # Calculates :memory_diff for each request based on the last completed request that was not a failure.
   def update_pids
     # memory isn't recorded with exceptions. need to set #last_memory_reading+ to -1 as
     # the memory used could have changed. for the next request the memory change will not be recorded.
     #
     # NOTE - the failure regex was not matching with a Rails Development log file.
     if has_line_type?(:failure) and processing = has_line_type?(:processing)
       file_format.pids[processing[:pid]][:last_memory_reading] = -1
     elsif mem_line = has_line_type?(:memory_usage)
        pid,memory_reading = mem_line.values_at(:pid,:memory)
        file_format.pids[pid] ||= { :last_memory_reading => -1, :current_memory_reading => -1 }
        file_format.pids[pid][:current_memory_reading] = memory_reading
        # calcuate the change in memory
        unless file_format.pids[pid][:current_memory_reading] == -1 || file_format.pids[pid][:last_memory_reading] == -1
          # logged as kB, need to convert to bytes for the :traffic Tracker
          memory_diff = (file_format.pids[pid][:current_memory_reading] - file_format.pids[pid][:last_memory_reading])*1024
          if memory_diff > 0
            self.attributes[:memory_diff] = memory_diff
          end # if memory_diff > 0
        end # unless
        
        file_format.pids[pid][:last_memory_reading] = file_format.pids[pid][:current_memory_reading]
        file_format.pids[pid][:current_memory_reading] = -1
      end # if mem_line
      return true
   end # def update_pids
  end # class Request
end