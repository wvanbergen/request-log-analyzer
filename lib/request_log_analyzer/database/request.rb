class RequestLogAnalyzer::Database::Request < RequestLogAnalyzer::Database::Base

  # Returns an array of all the Line objects of this request in the correct order.
  def lines
    @lines ||= begin
      lines = []
      self.class.reflections.each { |r, d| lines += self.send(r).all }
      lines.sort
    end
  end

  # Creates the table to store requests in.
  def self.create_table!
    unless database.connection.table_exists?(:requests)
      database.connection.create_table(:requests) do |t|
        t.column :first_lineno, :integer
        t.column :last_lineno,  :integer
      end
    end
  end

end
