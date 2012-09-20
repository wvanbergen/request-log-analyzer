# Setup the include path
$:.unshift(File.expand_path('..', File.dirname(__FILE__)))
require 'request_log_analyzer'
require 'request_log_analyzer/database'

$database = RequestLogAnalyzer::Database.new(ENV['RLA_DBCONSOLE_DATABASE'])
$database.load_database_schema!
$database.register_default_orm_classes!

require 'cli/tools'

def wordwrap(string, max = 80, indent = "")
  strings = [""]
  string.split(", ").each do |item|
    if strings.last.length == 0 || strings.last.length + item.length <= max
      strings.last << item << ', '
    else
      strings << (item + ', ')
    end
  end
  strings.map(&:strip).join("\n#{indent}").slice(0..-2)
end

class Request
  def inspect
    request_inspect = "Request[id: #{id}]"
    request_inspect << " <#{lines.first.source.filename}>" if lines.first.source

    inspected_lines = lines.map do |line|
      inspect_line = "   - #{line.line_type} (line #{line.lineno})"
      if (inspect_attributes = line.attributes.reject { |(k, v)| [:id, :source_id, :request_id, :lineno].include?(k.to_sym) }).any?
        inspect_attributes = inspect_attributes.map { |(k,v)| "#{k} = #{v.inspect}" }.join(', ')
        inspect_line << "\n      " + wordwrap(inspect_attributes, CommandLine::Tools.terminal_width - 6, "      ")
      end
      inspect_line
    end

    request_inspect << "\n" << inspected_lines.join("\n") << "\n\n"
  end
end

puts "request-log-analyzer database console"
puts "-------------------------------------"
puts "The following ActiveRecord classes are available:"
puts $database.orm_classes.map { |k| k.name.split('::').last }.join(", ")
