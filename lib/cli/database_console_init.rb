# Setup the include path
$:.unshift(File.dirname(__FILE__) + '/..')

# Load the file format
if ENV['RLA_DBCONSOLE_FORMAT_ARGUMENT']
  file_format = RequestLogAnalyzer::FileFormat.load(ENV['RLA_DBCONSOLE_FORMAT'], ENV['RLA_DBCONSOLE_FORMAT_ARGUMENT'])
else
  file_format = RequestLogAnalyzer::FileFormat.load(ENV['RLA_DBCONSOLE_FORMAT'])
end

$database = RequestLogAnalyzer::Database.new(ENV['RLA_DBCONSOLE_DATABASE'])
$database.load_database_schema!

puts "The following ActiveRecord classes are available:"
puts $database.orm_classes.join(", ")
