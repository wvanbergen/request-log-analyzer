require 'rubygems'
require 'activerecord'

module RequestLogAnalyzer::Aggregator

  class Database < Base

    attr_reader :request_id

    def prepare
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => options[:database])

      File.unlink(options[:database]) if File.exist?(options[:database])
      create_database_schema!
      
      @request_id = 0
    end
    
    def aggregate(request)
      @request_id += 1
      
      request.lines.each do |line|
        class_name = "#{line[:line_type]}_line".camelize #split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')
        
        attributes = line.reject { |k, v| [:line_type].include?(k) }
        attributes[:request_id] = @request_id if options[:combined_requests]  
        file_format.class.const_get(class_name).create!(attributes)
      end
    rescue SQLite3::SQLException => e
      raise Interrupt, e.message
    end
    
    def finalize
      ActiveRecord::Base.remove_connection
    end
    
    def warning(type, message, lineno)
      file_format.class::Warning.create!(:warning_type => type.to_s, :message => message, :lineno => lineno)
    end
    
    def report(reporth_width, color)
      puts
      puts green("━" * reporth_width, color)
      puts "A database file has been created with all parsed request information."
      puts "To execute queries on this database, run the following command:"
      puts "  $ sqlite3 #{options[:database]}"
      puts
    end
    
    protected 
    
    def create_database_table(name, definition)
      ActiveRecord::Migration.verbose = options[:debug]
      ActiveRecord::Migration.create_table("#{name}_lines") do |t|
        t.column(:request_id, :integer) #if options[:combined_requests]
        t.column(:lineno, :integer)
        definition.captures.each do |capture|
          t.column(capture[:name], column_type(capture))
        end
      end
    end

    def create_warning_table_and_class
      ActiveRecord::Migration.verbose = options[:debug]
      ActiveRecord::Migration.create_table("warnings") do |t|
        t.string  :warning_type, :limit => 30, :null => false
        t.string  :message
        t.integer :lineno          
      end    
      
      file_format.class.const_set('Warning', Class.new(ActiveRecord::Base)) unless file_format.class.const_defined?('Warning')
    end

    def create_activerecord_class(name, definition)
      class_name = "#{name}_line".camelize
      file_format.class.const_set(class_name, Class.new(ActiveRecord::Base)) unless file_format.class.const_defined?(class_name)
    end

    def create_database_schema!
      file_format.line_definitions.each do |name, definition|
        create_database_table(name, definition)
        create_activerecord_class(name, definition)
      end
      
      create_warning_table_and_class
    end
    
    def column_type(capture)
      case capture[:type]
      when :sec;   :double
      when :msec;  :double
      when :float; :double
      else         capture[:type]
      end
    end
  end
end
