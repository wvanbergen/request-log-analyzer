class RequestLogAnalyzer::Database::Base < ActiveRecord::Base
  
  self.abstract_class = true

  class << self; attr_accessor :database; end

  def self.subclass_from_line_definition(definition)
    klass = Class.new(RequestLogAnalyzer::Database::Base)
    klass.set_table_name("#{definition.name}_lines")
    
    # Set relations with requests and sources table
    klass.belongs_to :request
    klass.belongs_to :source
    
    # Serialize complex fields into the database
    definition.captures.select { |c| c.has_key?(:provides) }.each do |capture|
      klass.send(:serialize, capture[:name], Hash)
    end

    self.database.request_class.send :has_many, "#{definition.name}_lines".to_sym
    self.database.source_class.send  :has_many, "#{definition.name}_lines".to_sym
    
    return klass
  end
  
  def self.subclass_from_table(table)
    raise "Table #{table} not found!" unless database.connection.table_exists?(table)

    klass = Class.new(RequestLogAnalyzer::Database::Base)
    klass.set_table_name(table)

    if klass.column_names.include?('request_id')
      klass.send :belongs_to, :request
      database.request_class.send :has_many, table.to_sym
    end
    
    if klass.column_names.include?('source_id')
      klass.send :belongs_to, :source
      database.source_class.send :has_many, table.to_sym
    end
    
    return klass
  end
  
end