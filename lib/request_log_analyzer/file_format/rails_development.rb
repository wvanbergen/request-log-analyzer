module RequestLogAnalyzer::FileFormat
  
  # The RailsDevelopment FileFormat is an extention to the default Rails file format. It includes
  # all lines of the normal Rails file format, but parses SQL queries and partial rendering lines
  # as well.
  class RailsDevelopment < Rails
  
    #   Parameters: {"action"=>"demo", "controller"=>"page"}
    line_definition :parameters do |line|
      line.teaser = /Parameters/
      line.regexp = /\s+Parameters:\s+(\{.*\})/
      line.captures << { :name => :params, :type => :eval }
    end
  
    # Rendered layouts/_footer (2.9ms)
    line_definition :rendered do |line|
      line.regexp = /Rendered (\w+(?:\/\w+)+) \((\d+\.\d+)ms\)/
      line.captures << { :name => :render_file,     :type  => :string } \
                    << { :name => :render_duration, :type  => :duration, :unit => :msec }
    end
  
    #  [4;36;1mUser Load (0.4ms)[0m   [0;1mSELECT * FROM `users` WHERE (`users`.`id` = 18205844) [0m
    line_definition :query_executed do |line|
      line.regexp = /\s+(?:\e\[4;36;1m)?((?:\w+::)*\w+) Load \((\d+\.\d+)ms\)(?:\e\[0m)?\s+(?:\e\[0;1m)?([^\e]+) ?(?:\e\[0m)?/
      line.captures << { :name => :query_class,    :type  => :string } \
                    << { :name => :query_duration, :type  => :duration, :unit => :msec } \
                    << { :name => :query_sql,      :type  => :sql }
    end

    #  [4;35;1mCACHE (0.0ms)[0m   [0mSELECT * FROM `users` WHERE (`users`.`id` = 0) [0m  
    line_definition :query_cached do |line|
      line.regexp = /\s+(?:\e\[4;35;1m)?CACHE \((\d+\.\d+)ms\)(?:\e\[0m)?\s+(?:\e\[0m)?([^\e]+) ?(?:\e\[0m)?/
      line.captures << { :name => :cached_duration, :type  => :duration, :unit => :msec } \
                    << { :name => :cached_sql,      :type  => :sql }
    end  

    # Define the reporting for the additional parsed lines
    report(:append) do |analyze|
      
      analyze.duration :render_duration, :category => :render_file, :multiple_per_request => true, 
              :amount => 20, :title => 'Partial rendering duration'
              
      analyze.duration :query_duration, :category => :query_sql, :multiple_per_request => true, 
              :amount => 20, :title => 'Query duration'
              
    end  
    
    # Add a converter method for the SQL fields the the Rails request class
    class Request < Rails::Request
      
      # Sanitizes SQL queries so that they can be grouped
      def convert_sql(sql, definition) 
        sql.gsub(/\b\d+\b/, ':int').gsub(/`([^`]+)`/, '\1').gsub(/'[^']*'/, ':string').rstrip
      end
    end
  end
end
