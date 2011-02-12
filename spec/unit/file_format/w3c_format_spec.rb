require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::W3c do

  before(:each) do
    @file_format = RequestLogAnalyzer::FileFormat.load(:w3c)
    @log_parser  = RequestLogAnalyzer::Source::LogParser.new(@file_format)  
    #          date       time     c-ip cs-username s-ip     s-port  cs-method cs-uri-stem cs-uri-query sc-status sc-bytes cs-bytes time-taken cs(User-Agent) cs(Referrer) 
    @sample = '2002-05-24 20:18:01 172.224.24.114 - 206.73.118.24 80 GET /Default.htm - 200 7930 248 31 Mozilla/4.0+(compatible;+MSIE+5.01;+Windows+2000+Server) http://64.224.24.114/'
  end

  it "should be a valid file format" do
    @file_format.should be_valid
  end

  it "should parse access lines and capture all of its fields" do
    @file_format.should have_line_definition(:access).capturing(:timestamp, :remote_ip, :username, :local_ip, :port, :method, :path, :http_status, :bytes_sent, :bytes_received, :duration, :user_agent, :referer)
  end

  it "should match the sample line" do
    @file_format.parse_line(@sample).should include(:line_definition, :captures)
  end

  it "should not match a nonsense line" do
    @file_format.parse_line('#Software: Microsoft Internet Information Services 6.0').should be_nil
  end

  it "should parse and convert the sample fields correctly" do
    @log_parser.parse_io(StringIO.new(@sample)) do |request|
      request[:timestamp].should      == 20020524201801
      request[:remote_ip].should      == "172.224.24.114"
      request[:username].should       == nil
      request[:local_ip].should       == "206.73.118.24"
      request[:port].should           == 80
      request[:method].should         == 'GET'
      request[:path].should           == '/Default.htm'
      request[:http_status].should    == 200
      request[:bytes_sent].should     == 7930
      request[:bytes_received].should == 248
      request[:duration].should       == 0.031
      request[:user_agent].should     == 'Mozilla/4.0+(compatible;+MSIE+5.01;+Windows+2000+Server)'
      request[:referer].should        == 'http://64.224.24.114/'
    end
  end

end