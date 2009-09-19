class RequestLogAnalyzer::Database::Warning < RequestLogAnalyzer::Database::Base

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
