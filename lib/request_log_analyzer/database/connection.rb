module RequestLogAnalyzer::Database::Connection
  def self.from_string(string)
    hash = {}
    if string =~ /^(?:\w+=(?:[^;])*;)*\w+=(?:[^;])*$/
      string.scan(/(\w+)=([^;]*);?/) { |variable, value| hash[variable.to_sym] = value }
    elsif string =~ /^(\w+)\:\/\/(?:(?:([^:]+)(?:\:([^:]+))?\@)?([\w\.-]+)\/)?([\w\:\-\.\/]+)$/
      hash[:adapter], hash[:username], hash[:password], hash[:host], hash[:database] = Regexp.last_match[1], Regexp.last_match[2], Regexp.last_match[3], Regexp.last_match[4], Regexp.last_match[5]
      hash.delete_if { |_k, v| v.nil? }
    end
    hash.empty? ? nil : hash
  end

  def connect(connection_identifier)
    if connection_identifier.is_a?(Hash)
      ActiveRecord::Base.establish_connection(connection_identifier)
    elsif connection_identifier == ':memory:'
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    elsif connection_hash = RequestLogAnalyzer::Database::Connection.from_string(connection_identifier)
      ActiveRecord::Base.establish_connection(connection_hash)
    elsif connection_identifier.is_a?(String) # Normal SQLite 3 database file
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: connection_identifier)
    elsif connection_identifier.nil?
      nil
    else
      fail "Cannot connect with this connection_identifier: #{connection_identifier.inspect}"
    end
  end

  def disconnect
    RequestLogAnalyzer::Database::Base.remove_connection
  end

  def connection
    RequestLogAnalyzer::Database::Base.connection
  end
end
