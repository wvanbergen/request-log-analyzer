module RequestLogAnalyzer::FileFormat

  # Default FileFormat class for Rails logs.
  #
  # Instances will be created dynamically based on the lines you want it to parse. You can
  # specify what lines should be included in the parser by providing a list to the create
  # method as first argument.
  class Rails < Base

    extend CommonRegularExpressions

    # Creates a Rails FileFormat instance.
    #
    # The lines that will be parsed can be defined by the argument to this function, 
    # which should be an array of line names, or a list of line names as comma separated
    # string. The resulting report depends on the lines that will be parsed. You can 
    # also provide s string that describes a common set of lines, like "production",
    # "development" or "production".
    def self.create(lines = 'production')
      definitions_hash = line_definer.line_definitions.clone
      
      lines = lines.to_s.split(',') if lines.kind_of?(String)
      lines = [lines.to_s]          if lines.kind_of?(Symbol)
      
      lines.each do |line|
        line = line.to_sym
        if LINE_COLLECTIONS.has_key?(line)
          LINE_COLLECTIONS[line].each { |l| definitions_hash[l] ||= LINE_DEFINITIONS[l] }
        elsif LINE_DEFINITIONS.has_key?(line)
          definitions_hash[line] ||= LINE_DEFINITIONS[line]
        else
          raise "Unrecognized Rails log line name: #{line.inspect}!"
        end
      end

      return self.new(definitions_hash, report_trackers(definitions_hash))
    end
    
    # Creates trackers based on the specified line definitions.
    #
    # The more lines that will be parsed, the more information will appear in the report.
    def self.report_trackers(lines)
      analyze = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      
      analyze.timespan
      analyze.hourly_spread
      
      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Most requested'
      analyze.frequency :method, :title => 'HTTP methods'
      analyze.frequency :status, :title => 'HTTP statuses returned'
      
      if lines.has_key?(:cache_hit)
        analyze.frequency(:category => lambda { |request| request =~ :cache_hit ? 'Cache hit' : 'No hit' }, 
              :title => 'Rails action cache hits')
      end
      
      analyze.duration :duration, :category => REQUEST_CATEGORIZER, :title => "Request duration",    :line_type => :completed
      analyze.duration :view,     :category => REQUEST_CATEGORIZER, :title => "View rendering time", :line_type => :completed
      analyze.duration :db,       :category => REQUEST_CATEGORIZER, :title => "Database time",       :line_type => :completed
      
      analyze.frequency :category => REQUEST_CATEGORIZER, :title => 'Process blockers (> 1 sec duration)',
        :if => lambda { |request| request[:duration] && request[:duration] > 1.0 }
      
      if lines.has_key?(:failure)
        analyze.frequency :error, :title => 'Failed requests', :line_type => :failure
      end

      if lines.has_key?(:rendered)
        analyze.duration :render_duration, :category => :render_file, :multiple => true, :title => 'Partial rendering duration'
      end

      if lines.has_key?(:query_executed)
        analyze.duration :query_duration, :category => :query_sql, :multiple => true, :title => 'Query duration'
      end
      
      return analyze.trackers + report_definer.trackers
    end

    # Rails < 2.1 completed line example
    # Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]
    RAILS_21_COMPLETED = /Completed in (\d+\.\d{5}) \(\d+ reqs\/sec\) (?:\| Rendering: (\d+\.\d{5}) \(\d+\%\) )?(?:\| DB: (\d+\.\d{5}) \(\d+\%\) )?\| (\d\d\d).+\[(http.+)\]/

    # Rails > 2.1 completed line example
    # Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]
    RAILS_22_COMPLETED = /Completed in (\d+)ms \((?:View: (\d+))?,?(?:.?DB: (\d+))?\)? \| (\d{3}).+\[(http.+)\]/
                        
    # A hash of definitions for all common lines in Rails logs.
    LINE_DEFINITIONS = {
      :processing => RequestLogAnalyzer::LineDefinition.new(:processing, :header => true,
            :teaser   => /Processing /,
            :regexp   => /Processing ((?:\w+::)*\w+)#(\w+)(?: to (\w+))? \(for (#{ip_address}) at (#{timestamp('%Y-%m-%d %H:%M:%S')})\) \[([A-Z]+)\]/,
            :captures => [{ :name => :controller, :type  => :string },
                          { :name => :action,     :type  => :string },
                          { :name => :format,     :type  => :string, :default => 'html' },
                          { :name => :ip,         :type  => :string },
                          { :name => :timestamp,  :type  => :timestamp },
                          { :name => :method,     :type  => :string }]),

      :completed => RequestLogAnalyzer::LineDefinition.new(:completed, :footer => true,
            :teaser   => /Completed in /,
            :regexp   => Regexp.union(RAILS_21_COMPLETED, RAILS_22_COMPLETED),
            :captures => [{ :name => :duration, :type => :duration, :unit => :sec },   # First old variant capture
                          { :name => :view,     :type => :duration, :unit => :sec },
                          { :name => :db,       :type => :duration, :unit => :sec },
                          { :name => :status,   :type => :integer },
                          { :name => :url,      :type => :string },                    # Last old variant capture
                          { :name => :duration, :type => :duration, :unit => :msec },  # First new variant capture
                          { :name => :view,     :type => :duration, :unit => :msec },
                          { :name => :db,       :type => :duration, :unit => :msec },
                          { :name => :status,   :type => :integer },
                          { :name => :url,      :type => :string }]),                  # Last new variant capture

      :failure => RequestLogAnalyzer::LineDefinition.new(:failure, :footer => true,
          :teaser   => /((?:[A-Z]\w*[a-z]\w+\:\:)*[A-Z]\w*[a-z]\w+) \((.*)\)(?: on line #(\d+) of (.+))?\:/,
          :regexp   => /((?:[A-Z]\w*[a-z]\w+\:\:)*[A-Z]\w*[a-z]\w+) \((.*)\)(?: on line #(\d+) of (.+))?\:\s*$/,
          :captures => [{ :name => :error,       :type => :string },
                        { :name => :message,     :type => :string },
                        { :name => :line,        :type => :integer },
                        { :name => :file,        :type => :string }]),

      :cache_hit => RequestLogAnalyzer::LineDefinition.new(:cache_hit,
          :regexp => /Filter chain halted as \[\#<ActionController::Filters::AroundFilter.*\@method=.*(?:Caching::Actions::ActionCacheFilter|action_controller\/caching\/actions\.rb).*\] did_not_yield/),

      :parameters => RequestLogAnalyzer::LineDefinition.new(:parameters,
          :teaser   => /  Parameters:/,
          :regexp   => /  Parameters:\s+(\{.*\})/,
          :captures => [{ :name => :params, :type => :eval }]),

      :rendered => RequestLogAnalyzer::LineDefinition.new(:rendered,
          :teaser   => /Rendered /,
          :regexp   => /Rendered (\w+(?:\/\w+)+) \((\d+\.\d+)ms\)/,
          :captures => [{ :name => :render_file,     :type  => :string },
                        { :name => :render_duration, :type  => :duration, :unit => :msec }]),

      :query_executed => RequestLogAnalyzer::LineDefinition.new(:query_executed,
          :regexp   => /\s+(?:\e\[4;36;1m)?((?:\w+::)*\w+) Load \((\d+\.\d+)ms\)(?:\e\[0m)?\s+(?:\e\[0;1m)?([^\e]+) ?(?:\e\[0m)?/,
          :captures => [{ :name => :query_class,    :type  => :string },
                        { :name => :query_duration, :type  => :duration, :unit => :msec },
                        { :name => :query_sql,      :type  => :sql }]),

      :query_cached => RequestLogAnalyzer::LineDefinition.new(:query_cached,
          :regexp   => /\s+(?:\e\[4;35;1m)?CACHE \((\d+\.\d+)ms\)(?:\e\[0m)?\s+(?:\e\[0m)?([^\e]+) ?(?:\e\[0m)?/,
          :captures => [{ :name => :cached_duration, :type  => :duration, :unit => :msec },
                        { :name => :cached_sql,      :type  => :sql }])
    }

    # Definitions of common combinations of lines that can be parsed
    LINE_COLLECTIONS = {
      :minimal     => [:processing, :completed],
      :production  => [:processing, :completed, :failure, :cache_hit],
      :development => [:processing, :completed, :failure, :rendered, :query_executed, :query_cached],
      :all         => LINE_DEFINITIONS.keys
    }


    # Simple function to categorize Rails requests using controller/actions/format and method.
    REQUEST_CATEGORIZER = Proc.new do |request|
      "#{request[:controller]}##{request[:action]}.#{request[:format]} [#{request[:method]}]"
    end

    # Define a custom Request class for the Rails file format to speed up timestamp handling
    # and to ensure that a format is always set.
    class Request < RequestLogAnalyzer::Request

      # Do not use DateTime.parse
      def convert_timestamp(value, definition)
        value.gsub(/[^0-9]/, '')[0...14].to_i
      end

      # Sanitizes SQL queries so that they can be grouped
      def convert_sql(sql, definition)
        sql.gsub(/\b\d+\b/, ':int').gsub(/`([^`]+)`/, '\1').gsub(/'[^']*'/, ':string').rstrip
      end
    end
  end
end
