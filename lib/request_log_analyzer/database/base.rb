class RequestLogAnalyzer::Database::Base < ActiveRecord::Base

  self.abstract_class = true

  def <=>(other)
    if (source_id.nil? && other.source_id.nil?) || (source_comparison = source_id <=> other.source_id) == 0
      lineno <=> other.lineno
    else
      source_comparison
    end
  end
  
  # Handle format manually, because it is prohibidado in Rails 3.2.1
  def format=(arg)
    self.attributes[:format] = arg
  end
  
  def format(arg)
    self.attributes[:format]
  end

  def line_type
    self.class.name.underscore.gsub(/_line$/, '').to_sym
  end

  class_attribute :line_definition
  cattr_accessor :database

  def self.subclass_from_line_definition(definition, klass = Class.new(RequestLogAnalyzer::Database::Base))
    klass.table_name = "#{definition.name}_lines"

    klass.line_definition = definition

    # Set relations with requests and sources table
    klass.belongs_to :request, :class_name => RequestLogAnalyzer::Database::Request.name
    klass.belongs_to :source, :class_name => RequestLogAnalyzer::Database::Source.name

    # Serialize complex fields into the database
    definition.captures.select { |c| c.has_key?(:provides) }.each do |capture|
      klass.send(:serialize, capture[:name], Hash)
    end

    RequestLogAnalyzer::Database::Request.has_many  "#{definition.name}_lines".to_sym
    RequestLogAnalyzer::Database::Source.has_many   "#{definition.name}_lines".to_sym

    return klass
  end

  def self.subclass_from_table(table, klass = Class.new(RequestLogAnalyzer::Database::Base))
    raise "Table #{table} not found!" unless database.connection.table_exists?(table)
    
    klass.table_name = table

    if klass.column_names.include?('request_id')
      klass.belongs_to :request, :class_name => RequestLogAnalyzer::Database::Request.name
      RequestLogAnalyzer::Database::Request.has_many table.to_sym
    end

    if klass.column_names.include?('source_id')
      klass.belongs_to :source, :class_name => RequestLogAnalyzer::Database::Source.name
      RequestLogAnalyzer::Database::Source.has_many table.to_sym
    end

    return klass
  end

  def self.drop_table!
    database.connection.remove_index(self.table_name, [:source_id])  rescue nil
    database.connection.remove_index(self.table_name, [:request_id]) rescue nil
    database.connection.drop_table(self.table_name) if database.connection.table_exists?(self.table_name)
  end

  def self.create_table!
    raise "No line_definition available to base table schema on!" unless self.line_definition

    unless table_exists?
      database.connection.create_table(table_name.to_sym) do |t|

        # Default fields
        t.column :request_id, :integer
        t.column :source_id,  :integer
        t.column :lineno,     :integer

        line_definition.captures.each do |capture|
          column_name = capture[:name]
          column_name = 'file_format' if column_name == 'format'
          # Add a field for every capture
          t.column(column_name, column_type(capture[:type]))

          # If the capture provides other field as well, create columns for them, too
          capture[:provides].each { |field, field_type| t.column(field, column_type(field_type)) } if capture[:provides].kind_of?(Hash)
        end
      end
      
      # Add indices to table for more speedy querying
      database.connection.add_index(self.table_name.to_sym, [:request_id]) # rescue
      database.connection.add_index(self.table_name.to_sym, [:source_id])  # rescue
    end
  end

  # Function to determine the column type for a field
  # TODO: make more robust / include in file-format definition
  def self.column_type(type_indicator)
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