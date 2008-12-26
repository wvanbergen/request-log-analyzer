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
        file_format.const_get(class_name).create!(attributes)
      end
      
    end
    
    def warning(type, message, lineno)
      file_format::Warning.create!(:warning_type => type.to_s, :message => message, :lineno => lineno)
    end
    
    protected 
    
    def create_database_table(name, definition)
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table("#{name}_lines") do |t|
          t.column(:request_id, :integer) #if options[:combined_requests]
          t.column(:lineno, :integer)
          definition.captures.each do |field|
            # there is only on key/value pait in this hash
            field.each { |key, capture_type| t.column(key, column_type(capture_type)) }
          end
        end
      end
    end

    def create_warning_table_and_class
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table("warnings") do |t|
          t.string  :warning_type, :limit => 30, :null => false
          t.string  :message
          t.integer :lineno          
        end
      end    
      
      file_format.const_set('Warning', Class.new(ActiveRecord::Base)) unless file_format.const_defined?('Warning')
    end

    def create_activerecord_class(name, definition)
      class_name = "#{name}_line".camelize
      file_format.const_set(class_name, Class.new(ActiveRecord::Base)) unless file_format.const_defined?(class_name)
    end

    def create_database_schema!
      file_format.line_definitions.each do |name, definition|
        create_database_table(name, definition)
        create_activerecord_class(name, definition)
      end
      
      create_warning_table_and_class
    end
    
    def column_type(capture_type)
      case capture_type
      when :sec;   :double
      when :msec;  :double
      when :float; :double
      else capture_type
      end
    end
  end
end
