require 'rubygems'
require 'activerecord'

class RequestLogAnalyzer::Database

  def self.const_missing(const) # :nodoc:
    RequestLogAnalyzer::load_default_class_file(self, const)
  end  

  include RequestLogAnalyzer::Database::Connection

  attr_accessor :file_format
  attr_reader :request_class, :warning_class, :source_class, :line_classes
  
  def initialize(connection_identifier = nil)
    @line_classes = []
    RequestLogAnalyzer::Database::Base.database = self
    connect(connection_identifier)
  end

  # Returns the ORM class for the provided line type
  def get_class(line_type)
    line_type = line_type.name if line_type.respond_to?(:name)
    Object.const_get("#{line_type}_line".camelize)
  end
  
  # Returns the Request ORM class for the current database.
  #
  # It will create the class if not previously done so. The class will
  # include a create_table! method the migrate the database.
  def request_class
    @request_class ||= begin
      klass = Class.new(RequestLogAnalyzer::Database::Base) do
        
        def lines
          @lines ||= begin
            lines = []
            self.class.reflections.each { |r, d| lines += self.send(r).all }
            lines.sort
          end
        end
        
        # Creates the requests table
        def self.create_table!
          unless database.connection.table_exists?(:requests)
            database.connection.create_table(:requests) do |t|
              t.column :first_lineno, :integer
              t.column :last_lineno,  :integer
            end
          end
        end
      end
      
      Object.const_set('Request', klass) 
      Object.const_get('Request')
    end
  end
  
  # Returns the Source ORM class for the current database.
  #
  # It will create the class if not previously done so. The class will
  # include a create_table! method the migrate the database.  
  def source_class
    @source_class ||= begin
      klass = Class.new(RequestLogAnalyzer::Database::Base) do
        
        # Creates the sources table
        def self.create_table!
          unless database.connection.table_exists?(:sources)
            database.connection.create_table(:sources) do |t|
              t.column :filename, :string
              t.column :mtime,    :datetime
              t.column :filesize, :integer
            end
          end
        end
      end
      
      Object.const_set('Source', klass)
      Object.const_get('Source')
    end
  end
  
  
  # Returns the Warning ORM class for the current database.
  #
  # It will create the class if not previously done so. The class will
  # include a create_table! method the migrate the database.  
  def warning_class
    @warning_class ||= begin
      klass = Class.new(RequestLogAnalyzer::Database::Base) do
        
        # Creates the warnings table
        def self.create_table!
          unless database.connection.table_exists?(:warnings)
            database.connection.create_table(:warnings) do |t|
              t.column  :warning_type, :string, :limit => 30, :null => false
              t.column  :message, :string
              t.column  :source_id, :integer
              t.column  :lineno, :integer
            end
          end
        end
      end
      
      Object.const_set('Warning', klass)
      Object.const_get('Warning')
    end
  end
  
  # Loads the ORM classes by inspecting the tables in the current database
  def load_database_schema!
    connection.tables.map do |table|
      case table.to_sym
      when :warnings then warning_class
      when :sources  then source_class
      when :requests then request_class
      else load_activerecord_class(table)
      end
    end
  end
  
  # Returns an array of all the ActiveRecord-bases ORM classes for this database
  def orm_classes
    [warning_class, request_class, source_class] + line_classes
  end
  
  # Loads an ActiveRecord-based class that correspond to the given parameter, which can either be
  # a table name or a LineDefinition instance.
  def load_activerecord_class(linedefinition_or_table)
    
    case linedefinition_or_table
    when String, Symbol
      klass_name = linedefinition_or_table.to_s.singularize.camelize
      klass      = RequestLogAnalyzer::Database::Base.subclass_from_table(linedefinition_or_table)
    when RequestLogAnalyzer::LineDefinition
      klass_name = "#{linedefinition_or_table.name}_line".camelize
      klass      = RequestLogAnalyzer::Database::Base.subclass_from_line_definition(linedefinition_or_table)
    end
    
    Object.const_set(klass_name, klass)
    klass = Object.const_get(klass_name)
    @line_classes << klass
    return klass
  end  

  def fileformat_classes
    raise "No file_format provided!" unless file_format
    
    default_classes = [request_class, source_class, warning_class]
    line_classes    = file_format.line_definitions.map { |(name, definition)| load_activerecord_class(definition) }
    return default_classes + line_classes
  end

  # Creates the database schema and related ActiveRecord::Base subclasses that correspond to the 
  # file format definition. These ORM classes will later be used to create records in the database.
  def create_database_schema!
    fileformat_classes.each { |klass| klass.create_table! }
  end
  
  # Drops the table of all the ORM classes, and unregisters the classes
  def drop_database_schema!
    file_format ? fileformat_classes.map(&:drop_table!) : orm_classes.map(&:drop_table!)
    remove_orm_classes!
  end
  
  # Unregisters every ORM class constant
  def remove_orm_classes!
    orm_classes.each do |klass|
      if klass.respond_to?(:name) && !klass.name.blank?
#        klass_base_name = klass.name.split('::').last
        Object.send(:remove_const, klass.name) if Object.const_defined?(klass.name)
      end
    end
  end

end
