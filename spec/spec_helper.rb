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
      format.request(*fields)
    else
      format.request(fields)      
    end
  end
  
  def mock_source
    source = mock('RequestLogAnalyzer::Source::Base')
    source.stub!(:file_format).and_return(spec_format)
    source.stub!(:parsed_requests).and_return(2)
    source.stub!(:skipped_requests).and_return(1)    
    source.stub!(:parse_lines).and_return(10)
    source.stub!(:each_request) do
      yield spec_format.request(:field => 'value1')
      yield spec_format.request(:field => 'value2')      
    end
    return source
  end

  def mock_io
    mio = mock('IO')
    mio.stub!(:print)
    mio.stub!(:puts)    
    mio.stub!(:write)
    return mio
  end
  
  def mock_output
    output = mock('RequestLogAnalyzer::Output::Base')
    output.stub!(:header)
    output.stub!(:footer)   
    output.stub!(:puts)
    output.stub!(:<<)    
    output.stub!(:title)
    output.stub!(:line)
    output.stub!(:with_style)    
    output.stub!(:table) { yield [] }
    output.stub!(:io).and_return(mock_io)
    return output
  end
  
end

