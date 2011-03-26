require 'rubygems'
require 'active_record'

class RequestLogAnalyzer::Database

  require 'request_log_analyzer/database/connection'
  include RequestLogAnalyzer::Database::Connection

  attr_accessor :file_format
  attr_reader :line_classes

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

  def default_classes
    [RequestLogAnalyzer::Database::Request, RequestLogAnalyzer::Database::Source, RequestLogAnalyzer::Database::Warning]
  end

  # Loads the ORM classes by inspecting the tables in the current database
  def load_database_schema!
    connection.tables.map do |table|
      case table.to_sym
      when :warnings then RequestLogAnalyzer::Database::Warning
      when :sources  then RequestLogAnalyzer::Database::Source
      when :requests then RequestLogAnalyzer::Database::Request
      else load_activerecord_class(table)
      end
    end
  end

  # Returns an array of all the ActiveRecord-bases ORM classes for this database
  def orm_classes
    default_classes + line_classes
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

  # Registers the default ORM classes in the default namespace
  def register_default_orm_classes!
    Object.const_set('Request', RequestLogAnalyzer::Database::Request)
    Object.const_set('Source',  RequestLogAnalyzer::Database::Source)
    Object.const_set('Warning', RequestLogAnalyzer::Database::Warning)
  end

  # Unregisters every ORM class constant
  def remove_orm_classes!
    orm_classes.each do |klass|
      if klass.respond_to?(:name) && !klass.name.blank?
        klass_name = klass.name.split('::').last
        Object.send(:remove_const, klass_name) if Object.const_defined?(klass_name)
      end
    end
  end
end

require 'request_log_analyzer/database/base'
require 'request_log_analyzer/database/request'
require 'request_log_analyzer/database/source'
require 'request_log_analyzer/database/warning'
