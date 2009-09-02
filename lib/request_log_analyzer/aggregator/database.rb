require 'rubygems'
require 'activerecord'

module RequestLogAnalyzer::Aggregator

  # The database aggregator will create an SQLite3 database with all parsed request information.
  #
  # The prepare method will create a database schema according to the file format definitions.
  # It will also create ActiveRecord::Base subclasses to interact with the created tables. 
  # Then, the aggregate method will be called for every parsed request. The information of
  # these requests is inserted into the tables using the ActiveRecord classes.
  #
  # A requests table will be created, in which a record is inserted for every parsed request.
  # For every line type, a separate table will be created with a request_id field to point to
  # the request record, and a field for every parsed value. Finally, a warnings table will be
  # created to log all parse warnings.
  class Database < Base

    attr_reader :request_class, :request_count, :orm_module, :warning_class

    # Establishes a connection to the database and creates the necessary database schema for the
    # current file format
    def prepare
      initialize_orm_module!
      establish_database_connection!
      File.unlink(options[:database]) if File.exist?(options[:database]) # TODO: keep old database?
      create_database_schema!
    end
    
    # Aggregates a request into the database
    # This will create a record in the requests table and create a record for every line that has been parsed,
    # in which the captured values will be stored.
    def aggregate(request)
      @request_object = request_class.new(:first_lineno => request.first_lineno, :last_lineno => request.last_lineno)
      request.lines.each do |line|
        class_columns = orm_module.const_get("#{line[:line_type]}_line".classify).column_names.reject { |column| ['id'].include?(column) }
        attributes = Hash[*line.select { |(k, v)| class_columns.include?(k.to_s) }.flatten]
        @request_object.send("#{line[:line_type]}_lines").build(attributes)
      end
      @request_object.save!
    rescue SQLite3::SQLException => e
      raise Interrupt, e.message
    end
    
    # Finalizes the aggregator by closing the connection to the database
    def finalize
      @request_count = orm_module::Request.count
      remove_database_connection!
      deinitialize_orm_module!
    end
    
    # Records w warining in the warnings table.
    def warning(type, message, lineno)
      warning_class.create!(:warning_type => type.to_s, :message => message, :lineno => lineno)
    end
    
    # Prints a short report of what has been inserted into the database
    def report(output)
      output.title('Request database created')
      
      output <<  "A database file has been created with all parsed request information.\n"
      output <<  "#{@request_count} requests have been added to the database.\n"      
      output <<  "To execute queries on this database, run the following command:\n"
      output <<  output.colorize("  $ sqlite3 #{options[:database]}\n", :bold)
      output << "\n"
    end
    
    # Retreives the connection that is used for the database inserter
    def connection
      orm_module::Base.connection
    end    
    
    protected 
    
    # Create a module and a default subclass of ActiveRecord::Base on which to establish the database connection
    def initialize_orm_module!
      
      # Create a Database module in the file format if it does not yet exists
      file_format.class.const_set('Database', Module.new) unless file_format.class.const_defined?('Database')
      @orm_module = file_format.class.const_get('Database')
      
      # Register the base activerecord class
      unless orm_module.const_defined?('Base')
        orm_base_class = Class.new(ActiveRecord::Base)
        orm_base_class.abstract_class = true
        orm_module.const_set('Base', orm_base_class)
      end
    end

    # Deinitializes the ORM module and the ActiveRecord::Base subclass.
    def deinitialize_orm_module!
      file_format.class.send(:remove_const, 'Database') if file_format.class.const_defined?('Database')
      @orm_module = nil
    end

    # Established a connection with the database for this session
    def establish_database_connection!
      orm_module::Base.establish_connection(:adapter => 'sqlite3', :database => options[:database])
      #ActiveRecord::Migration.class_eval("def self.connection; #{@orm_module.to_s}::Base.connection; end ")
    end

    def remove_database_connection!
      #ActiveRecord::Migration.class_eval("def self.connection; ActiveRecord::Base.connection; end ")      
      orm_module::Base.remove_connection
    end
    
    # This function creates a database table for a given line definition.
    # It will create a field for every capture in the line, and adds a lineno field to indicate at
    # what line in the original file the line was found, and a request_id to link lines related
    # to the same request. It will also create an index in the request_id field to speed up queries.
    def create_database_table(definition)
      connection.create_table("#{definition.name}_lines") do |t|
        
        # Add default fields for every line type
        t.column(:request_id, :integer)
        t.column(:lineno, :integer)
        
        definition.captures.each do |capture|
          # Add a field for every capture
          t.column(capture[:name], column_type(capture[:type]))

          # If the capture provides other field as well, create columns for them, too
          capture[:provides].each { |field, field_type| t.column(field, column_type(field_type)) } if capture[:provides].kind_of?(Hash)
        end
      end
      
      # Create an index on the request_id column to support faster querying
      connection.add_index("#{definition.name}_lines", [:request_id])
    end
    
    # Creates an ActiveRecord class for a given line definition.
    # A subclass of ActiveRecord::Base is created and an association with the Request class is
    # created using belongs_to / has_many. This association will later be used to create records
    # in the corresponding table. This table should already be created before this method is called.
    def create_activerecord_class(definition)
      class_name = "#{definition.name}_line".camelize
      klass = Class.new(orm_module::Base)
      klass.send(:belongs_to, :request)
      
      definition.captures.select { |c| c.has_key?(:provides) }.each do |capture|
        klass.send(:serialize, capture[:name], Hash)
      end
      
      orm_module.const_set(class_name, klass) unless orm_module.const_defined?(class_name)
      request_class.send(:has_many, "#{definition.name}_lines".to_sym)
    end    
    
    # Creates a requests table, in which a record is created for every request. It also creates an
    # ActiveRecord::Base class to communicate with this table.
    def create_request_table_and_class
      connection.create_table("requests") do |t|
        t.column :first_lineno, :integer
        t.column :last_lineno,  :integer
      end    
      
      orm_module.const_set('Request', Class.new(orm_module::Base)) unless orm_module.const_defined?('Request')     
      @request_class = orm_module.const_get('Request')
    end

    # Creates a warnings table and a corresponding Warning class to communicate with this table using ActiveRecord.
    def create_warning_table_and_class
      connection.create_table("warnings") do |t|
        t.column  :warning_type, :string, :limit => 30, :null => false
        t.column  :message, :string
        t.column  :lineno, :integer
      end    
      
      orm_module.const_set('Warning', Class.new(orm_module::Base)) unless orm_module.const_defined?('Warning')
      @warning_class = orm_module.const_get('Warning')
    end
    
    # Creates the database schema and related ActiveRecord::Base subclasses that correspond to the 
    # file format definition. These ORM classes will later be used to create records in the database.
    def create_database_schema!
      create_request_table_and_class
      create_warning_table_and_class
      
      file_format.line_definitions.each do |name, definition|
        create_database_table(definition)
        create_activerecord_class(definition)
      end
    end
    
    # Function to determine the column type for a field
    # TODO: make more robust / include in file-format definition
    def column_type(type_indicator)
      case type_indicator
      when :eval;      :text
      when :hash;      :text
      when :text;      :text
      when :string;    :string
      when :sec;       :double
      when :msec;      :double
      when :duration;  :double
      when :float;     :double
      when :double;    :double
      when :integer;   :integer
      when :int;       :int
      when :timestamp; :datetime
      when :datetime;  :datetime
      when :date;      :date
      else             :string
      end
    end
  end
end
