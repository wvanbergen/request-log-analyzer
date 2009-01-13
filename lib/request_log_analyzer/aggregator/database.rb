require 'rubygems'
require 'activerecord'

module RequestLogAnalyzer::Aggregator

  class Database < Base

    attr_reader :request_id

    def prepare
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => options[:database])

      File.unlink(options[:database]) if File.exist?(options[:database])
      create_database_schema!
    end
    
    def aggregate(request)
      @request_object = @request_class.new(:first_lineno => request.first_lineno, :last_lineno => request.last_lineno)
      request.lines.each do |line|
        attributes = line.reject { |k, v| [:line_type].include?(k) }
        @request_object.send("#{line[:line_type]}_lines").build(attributes)
      end
      @request_object.save!
    rescue SQLite3::SQLException => e
      raise Interrupt, e.message
    end
    
    def finalize
      ActiveRecord::Base.remove_connection
    end
    
    def warning(type, message, lineno)
      @orm_module::Warning.create!(:warning_type => type.to_s, :message => message, :lineno => lineno)
    end
    
    def report(output = STDOUT, report_width = 80, color = false)
      output << "\n"
      output << green("━" * report_width, color) + "\n"
      output <<  "A database file has been created with all parsed request information.\n"
      output <<  "To execute queries on this database, run the following command:\n"
      output <<  "  $ sqlite3 #{options[:database]}\n"
      output << "\n"
    end
    
    protected 
    
    def create_database_table(name, definition)
      ActiveRecord::Migration.verbose = options[:debug]
      ActiveRecord::Migration.create_table("#{name}_lines") do |t|
        t.column(:request_id, :integer)
        t.column(:lineno, :integer)
        definition.captures.each do |capture|
          t.column(capture[:name], column_type(capture))
        end
      end
    end
    
    def create_request_table_and_class
      ActiveRecord::Migration.verbose = options[:debug]
      ActiveRecord::Migration.create_table("requests") do |t|
        t.integer :first_lineno
        t.integer :last_lineno
      end    
      
      @orm_module.const_set('Request', Class.new(ActiveRecord::Base)) unless @orm_module.const_defined?('Request')     
      @request_class = @orm_module.const_get('Request')
    end

    def create_warning_table_and_class
      ActiveRecord::Migration.verbose = options[:debug]
      ActiveRecord::Migration.create_table("warnings") do |t|
        t.string  :warning_type, :limit => 30, :null => false
        t.string  :message
        t.integer :lineno          
      end    
      
      @orm_module.const_set('Warning', Class.new(ActiveRecord::Base)) unless @orm_module.const_defined?('Warning')
    end

    def create_activerecord_class(name, definition)
      class_name = "#{name}_line".camelize
      @orm_module.const_set(class_name, Class.new(ActiveRecord::Base)) unless @orm_module.const_defined?(class_name)
      @request_class.send(:has_many, "#{name}_lines".to_sym)
    end

    def create_database_schema!
      
      if file_format.class.const_defined?('Database')
        @orm_module = file_format.class.const_get('Database')
      else
        @orm_module = file_format.class.const_set('Database', Module.new)
      end

      create_request_table_and_class
      create_warning_table_and_class
      
      file_format.line_definitions.each do |name, definition|
        create_database_table(name, definition)
        create_activerecord_class(name, definition)
      end
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
