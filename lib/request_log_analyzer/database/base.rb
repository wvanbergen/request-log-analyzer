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
    attributes[:format] = arg
  end

  def format(_arg)
    attributes[:format]
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
    klass.belongs_to :request, class_name: RequestLogAnalyzer::Database::Request.name
    klass.belongs_to :source, class_name: RequestLogAnalyzer::Database::Source.name

    # Serialize complex fields into the database
    definition.captures.select { |c| c.key?(:provides) }.each do |capture|
      klass.send(:serialize, capture[:name], Hash)
    end

    RequestLogAnalyzer::Database::Request.has_many "#{definition.name}_lines".to_sym
    RequestLogAnalyzer::Database::Source.has_many "#{definition.name}_lines".to_sym

    klass
  end

  def self.subclass_from_table(table, klass = Class.new(RequestLogAnalyzer::Database::Base))
    fail "Table #{table} not found!" unless database.connection.table_exists?(table)

    klass.table_name = table

    if klass.column_names.include?('request_id')
      klass.belongs_to :request, class_name: RequestLogAnalyzer::Database::Request.name
      RequestLogAnalyzer::Database::Request.has_many table.to_sym
    end

    if klass.column_names.include?('source_id')
      klass.belongs_to :source, class_name: RequestLogAnalyzer::Database::Source.name
      RequestLogAnalyzer::Database::Source.has_many table.to_sym
    end

    klass
  end

  def self.drop_table!
    database.connection.remove_index(table_name, [:source_id])  rescue nil
    database.connection.remove_index(table_name, [:request_id]) rescue nil
    database.connection.drop_table(table_name) if database.connection.table_exists?(table_name)
  end

  def self.create_table!
    fail 'No line_definition available to base table schema on!' unless line_definition

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
          capture[:provides].each { |field, field_type| t.column(field, column_type(field_type)) } if capture[:provides].is_a?(Hash)
        end
      end

      # Add indices to table for more speedy querying
      database.connection.add_index(table_name.to_sym, [:request_id]) # rescue
      database.connection.add_index(table_name.to_sym, [:source_id])  # rescue
    end
  end

  # Function to determine the column type for a field
  # TODO: make more robust / include in file-format definition
  def self.column_type(type_indicator)
    case type_indicator
    when :eval then      :text
    when :hash then      :text
    when :text then      :text
    when :string then    :string
    when :sec then       :float
    when :msec then      :float
    when :duration then  :float
    when :float then     :float
    when :double then    :float
    when :integer then   :integer
    when :int then       :int
    when :timestamp then :datetime
    when :datetime then  :datetime
    when :date then      :date
    else             :string
    end
  end
end
