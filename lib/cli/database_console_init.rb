# Load the file format
if ENV['RLA_DBCONSOLE_FORMAT_ARGUMENT']
  file_format = RequestLogAnalyzer::FileFormat.load(ENV['RLA_DBCONSOLE_FORMAT'], ENV['RLA_DBCONSOLE_FORMAT_ARGUMENT'])
else
  file_format = RequestLogAnalyzer::FileFormat.load(ENV['RLA_DBCONSOLE_FORMAT'])
end

$database    = RequestLogAnalyzer::Database.new(file_format, ENV['RLA_DBCONSOLE_DATABASE'])
$database.create_database_schema!

class Object
  def self.const_missing(name)
    if $database.orm_module.const_defined?(name)
      $database.orm_module.const_get(name)
    else
      super(name)
    end
  end
end
