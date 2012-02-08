module RequestLogAnalyzer::Database::Connection

  def self.from_string(string)
    hash = {}
    if string =~ /^(?:\w+=(?:[^;])*;)*\w+=(?:[^;])*$/
      string.scan(/(\w+)=([^;]*);?/) { |variable, value| hash[variable.to_sym] = value }
    elsif string =~ /^(\w+)\:\/\/(?:(?:([^:]+)(?:\:([^:]+))?\@)?([\w\.-]+)\/)?([\w\:\-\.\/]+)$/
      hash[:adapter], hash[:username], hash[:password], hash[:host], hash[:database] = $1, $2, $3, $4, $5
      hash.delete_if { |k, v| v.nil? }
    end
    return hash.empty? ? nil : hash
  end

  def connect(connection_identifier)
    if connection_identifier.kind_of?(Hash)
      ActiveRecord::Base.establish_connection(connection_identifier)
    elsif connection_identifier == ':memory:'
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
    elsif connection_hash = RequestLogAnalyzer::Database::Connection.from_string(connection_identifier)
      ActiveRecord::Base.establish_connection(connection_hash)
    elsif connection_identifier.kind_of?(String) # Normal SQLite 3 database file
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => connection_identifier)
    elsif connection_identifier.nil?
      nil
    else
      raise "Cannot connect with this connection_identifier: #{connection_identifier.inspect}"
    end
  end

  def disconnect
    RequestLogAnalyzer::Database::Base.remove_connection
  end

  def connection
    RequestLogAnalyzer::Database::Base.connection
  end

end
