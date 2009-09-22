class RequestLogAnalyzer::Database::Source < RequestLogAnalyzer::Database::Base

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
