require 'rubygems'
require 'activerecord'

class RequestLogAnalyzer::Database

  def self.parse_connection_string(string)
    hash = {}
    if string =~ /^(?:\w+=(?:[^;])*;)*\w+=(?:[^;])*$/
      string.scan(/(\w+)=([^;]*);?/) { |variable, value| hash[variable.to_sym] = value }
    elsif string =~ /^(\w+)\:\/\/(?:(?:([^:]+)(?:\:([^:]+))?\@)?([\w\.-]+)\/)?([\w\:\-\.\/]+)$/
      hash[:adapter], hash[:username], hash[:password], hash[:host], hash[:database] = $1, $2, $3, $4, $5
      hash.delete_if { |k, v| v.nil? }
    end
    return hash.empty? ? nil : hash
  end
  
  attr_reader :file_format, :orm_module
  attr_reader :request_class, :warning_class, :source_class
  
  def initialize(file_format, connection_identifier, orm_module = nil)
    @file_format = file_format 

    if orm_module.nil?
      file_format.class.const_set('Database', Module.new) unless file_format.class.const_defined?('Database')
      @orm_module = file_format.class.const_get('Database')
    end
    
    create_base_orm_class!
    connect(connection_identifier)
  end
  
  def create_base_orm_class!
    # Register the base activerecord class
    unless orm_module.const_defined?('Base')
      orm_base_class = Class.new(ActiveRecord::Base)
      orm_base_class.abstract_class = true
      orm_module.const_set('Base', orm_base_class)
    end  
  end
  
  def remove_orm_classes!
    
    orm_module.send(:remove_const, 'Request') if orm_module.const_defined?('Request')
    orm_module.send(:remove_const, 'Warning') if orm_module.const_defined?('Warning')
    orm_module.send(:remove_const, 'Source')  if orm_module.const_defined?('Source')
    
    file_format.line_definitions.each do |name, definition| 
      orm_module.send(:remove_const, "#{name}_line".camelize) if orm_module.const_defined?("#{name}_line".camelize)
    end
  end
  
  def connect(connection_identifier)
    if connection_identifier.kind_of?(Hash)
      orm_module::Base.establish_connection(connection_identifier)
    elsif connection_identifier == ':memory:'
      orm_module::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    elsif connection_hash = RequestLogAnalyzer::Database.parse_connection_string(connection_identifier)
      orm_module::Base.establish_connection(connection_hash)
    elsif connection_identifier.kind_of?(String) # Normal SQLite 3 database file
      orm_module::Base.establish_connection(:adapter => 'sqlite3', :database => connection_identifier)
    elsif connection_identifier.nil?
      # Do nothing
    else
      raise "Cannot connect to database with #{connection_identifier.inspect}!"
    end
  end
  
  def disconnect
    orm_module::Base.remove_connection
  end
  
  def connection
    orm_module::Base.connection
  end
  
  def get_class(line_type)
    orm_module.const_get("#{line_type}_line".camelize)
  end
  
  # This function creates a database table for a given line definition.
  # It will create a field for every capture in the line, and adds a lineno field to indicate at
  # what line in the original file the line was found, and a request_id to link lines related
  # to the same request. It will also create an index in the request_id field to speed up queries.
  def create_database_table(definition)
    table_name = "#{definition.name}_lines".to_sym
    unless connection.table_exists?(table_name)
      connection.create_table(table_name) do |t|

        # Add default fields for every line type
        t.column(:request_id, :integer)
        t.column(:source_id, :integer)
        t.column(:lineno, :integer)
      
        definition.captures.each do |capture|
          # Add a field for every capture
          t.column(capture[:name], column_type(capture[:type]))

          # If the capture provides other field as well, create columns for them, too
          capture[:provides].each { |field, field_type| t.column(field, column_type(field_type)) } if capture[:provides].kind_of?(Hash)
        end
      end
    
      # Create an index on the request_id column to support faster querying
      connection.add_index(table_name, [:request_id])
    else
      # assume correct. 
      # TODO: check table for problems
    end
  end
  
  # Creates an ActiveRecord class for a given line definition.
  # A subclass of ActiveRecord::Base is created and an association with the Request class is
  # created using belongs_to / has_many. This association will later be used to create records
  # in the corresponding table. This table should already be created before this method is called.
  def create_activerecord_class(definition)
    class_name = "#{definition.name}_line".camelize
    unless orm_module.const_defined?(class_name)
      orm_module.const_set(class_name, Class.new(orm_module::Base))
      klass = orm_module.const_get(class_name)
      klass.send(:belongs_to, :request)
      klass.send(:belongs_to, :source)
          
      definition.captures.select { |c| c.has_key?(:provides) }.each do |capture|
        klass.send(:serialize, capture[:name], Hash)
      end
      
      self.request_class.send(:has_many, "#{definition.name}_lines".to_sym)
      self.source_class.send(:has_many, "#{definition.name}_lines".to_sym)
    end
  end

  # Creates a requests table, in which a record is created for every parsed request. 
  # It also creates an ActiveRecord::Base class to communicate with this table.
  def create_request_table_and_class
    unless connection.table_exists?(:requests)
      connection.create_table(:requests) do |t|
        t.column :first_lineno, :integer
        t.column :last_lineno,  :integer
      end    
    end
    
    orm_module.const_set('Request', Class.new(orm_module::Base)) unless orm_module.const_defined?('Request')
    @request_class = orm_module.const_get('Request')
  end

  # Creates a sources table, in which a record is created for every file that is parsed. 
  # It also creates an ActiveRecord::Base ORM class for the table.
  def create_source_table_and_class
    unless connection.table_exists?(:sources)
      connection.create_table(:sources) do |t|
        t.column :filename, :string
        t.column :mtime,    :datetime
        t.column :filesize, :integer
      end
    end
    
    orm_module.const_set('Source', Class.new(orm_module::Base)) unless orm_module.const_defined?('Source')
    @source_class = orm_module.const_get('Source')      
  end

  # Creates a warnings table and a corresponding Warning class to communicate with this table using ActiveRecord.
  def create_warning_table_and_class
    unless connection.table_exists?(:warnings)
      connection.create_table(:warnings) do |t|
        t.column  :warning_type, :string, :limit => 30, :null => false
        t.column  :message, :string
        t.column  :source_id, :integer
        t.column  :lineno, :integer
      end    
    end
    
    orm_module.const_set('Warning', Class.new(orm_module::Base)) unless orm_module.const_defined?('Warning')
    @warning_class = orm_module.const_get('Warning')
    @warning_class.send(:belongs_to, :source)
  end
  
  # Creates the database schema and related ActiveRecord::Base subclasses that correspond to the 
  # file format definition. These ORM classes will later be used to create records in the database.
  def create_database_schema!
    create_request_table_and_class
    create_warning_table_and_class
    create_source_table_and_class
        
    file_format.line_definitions.each do |name, definition|
      create_database_table(definition)
      create_activerecord_class(definition)
    end
  end
  
  def drop_database_schema!
    connection.drop_table(:sources)  if connection.table_exists?(:sources)
    connection.drop_table(:requests) if connection.table_exists?(:requests)
    connection.drop_table(:warnings) if connection.table_exists?(:warnings)
    
    file_format.line_definitions.each do |name, definition|
      table_name = "#{definition.name}_lines".to_sym
      connection.drop_table(table_name) if connection.table_exists?(table_name)
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
