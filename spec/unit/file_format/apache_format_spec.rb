require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Apache do
  
  before(:each) do
    @file_format = RequestLogAnalyzer::FileFormat.load(:apache)
    @log_parser = RequestLogAnalyzer::Source::LogParser.new(@file_format)
    @sample = '69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"'
  end
  
  it "should have a valid language definitions" do
    @file_format.should be_valid
  end
  
  it "should parse a valid access log line" do
    @file_format.line_definitions[:access].matches(@sample, 1, nil).should be_kind_of(Hash)
  end

  it "should read the correct values from a valid access log line" do
    @log_parser.parse_io(@sample) do |request|
      request[:ip_address].should   == '69.41.0.45'
      request[:timestamp].should    == 20090902120240
      request[:status].should       == 404
      request[:method].should       == 'GET'
      request[:http_version].should == '1.1'
    end
  end
  
  it "should parse 5 request from fixture access log" do
    counter = mock('counter')
    counter.should_receive(:hit!).exactly(5).times
    @log_parser.parse_file(log_fixture(:apache)) { counter.hit! }
  end

end
