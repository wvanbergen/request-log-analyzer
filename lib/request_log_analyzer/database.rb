require 'rubygems'
require 'activerecord'

class RequestLogAnalyzer::Database

  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end  

  include RequestLogAnalyzer::Database::Connection

  attr_accessor :file_format
  attr_reader :orm_module, :request_class, :warning_class, :source_class
  
  def initialize(connection_identifier = nil, orm_module = nil)
    @orm_module = orm_module.nil? ? Object : orm_module
    RequestLogAnalyzer::Database::Base.database = self
    connect(connection_identifier)
  end

  def remove_orm_classes!    
    orm_module.send(:remove_const, 'Request') if orm_module.const_defined?('Request')
    orm_module.send(:remove_const, 'Warning') if orm_module.const_defined?('Warning')
    orm_module.send(:remove_const, 'Source')  if orm_module.const_defined?('Source')
    
    if file_format
      file_format.line_definitions.each do |name, definition| 
        orm_module.send(:remove_const, "#{name}_line".camelize) if orm_module.const_defined?("#{name}_line".camelize)
      end
    end
  end
  
  def get_class(line_type)
    orm_module.const_get("#{line_type}_line".camelize)
  end
  
  def request_class
    @request_class ||= begin
      orm_module.const_set('Request', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Request')
      orm_module.const_get('Request')
    end
  end
  
  def source_class
    @source_class ||= begin
      orm_module.const_set('Source', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Source')
      orm_module.const_get('Source')
    end
  end
  
  def warning_class
    @warning_class ||= begin
      orm_module.const_set('Warning', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Warning')
      orm_module.const_get('Warning')
    end
  end
  
  def load_database_schema!
    connection.tables.each do |table|
      case table.to_sym
      when :warnings then warning_class
      when :sources  then source_class
      when :requests then request_class
      else load_activerecord_class(table)
      end
    end
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
  
  def load_activerecord_class(table)
    class_name = table.singularize.camelize
    unless orm_module.const_defined?(class_name)
      orm_module.const_set(class_name, RequestLogAnalyzer::Database::Base.subclass_from_table(table))
      klass = orm_module.const_get(class_name)
    end
  end  
  
  # Creates an ActiveRecord class for a given line definition.
  # A subclass of ActiveRecord::Base is created and an association with the Request class is
  # created using belongs_to / has_many. This association will later be used to create records
  # in the corresponding table. This table should already be created before this method is called.
  def create_activerecord_class(definition)
    class_name = "#{definition.name}_line".camelize
    unless orm_module.const_defined?(class_name)
      orm_module.const_set(class_name, RequestLogAnalyzer::Database::Base.subclass_from_line_definition(definition))
      klass = orm_module.const_get(class_name)
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
    
    orm_module.const_set('Request', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Request')
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
    
    orm_module.const_set('Source', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Source')
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
    
    orm_module.const_set('Warning', Class.new(RequestLogAnalyzer::Database::Base)) unless orm_module.const_defined?('Warning')
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
