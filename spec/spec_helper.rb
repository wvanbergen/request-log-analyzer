$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'
require 'request_log_analyzer'

module RequestLogAnalyzerSpecHelper
  
  def format_file(format)
    File.dirname(__FILE__) + "/file_formats/#{format}.rb"
  end
  
  def spec_format
    @spec_format ||= begin
      require format_file(:spec_format)
      SpecFormat.new
    end
  end
      
  def log_fixture(name)
    File.dirname(__FILE__) + "/fixtures/#{name}.log"
  end
  
  def request(fields, format = spec_format)
    if fields.kind_of?(Array)
      format.create_request(*fields)
    else
      format.create_request(fields)      
    end
  end
  
end

