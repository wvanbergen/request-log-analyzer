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

  def mock_io
    mio = mock('IO')
    mio.stub!(:print)
    mio.stub!(:puts)    
    mio.stub!(:write)
    return mio
  end
  
  def mock_output
    output = mock('RequestLogAnalyzer::Output')
    output.stub!(:header)
    output.stub!(:footer)    
    output.stub!(:io).and_return(mock_io)
    return output
  end
  
end

