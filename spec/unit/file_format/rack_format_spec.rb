require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Rack do

  context '"Sinatra" access log parsing' do

    before(:each) do
      @file_format      = RequestLogAnalyzer::FileFormat.load(:rack)
      @log_parser       = RequestLogAnalyzer::Source::LogParser.new(@file_format)    
      @sample = '127.0.0.1 - - [23/Nov/2009 21:47:47] "GET /css/stylesheet.css HTTP/1.1" 200 3782 0.0024'
    end

    it "should be a valid file format" do
      @file_format.should be_valid
    end

    it "should parse access lines and capture all of its fields" do
      @file_format.should have_line_definition(:access).capturing(:remote_host, :timestamp, :http_method, :path, :http_version, 
        :http_status, :bytes_sent, :duration)
    end

    it "should match the sample line" do
      @file_format.parse_line(@sample).should include(:line_definition, :captures)
    end

    it "should not match a nonsense line" do
      @file_format.parse_line('== Sinatra/0.9.4 has taken the stage on 4567 for development with backup from Mongrel').should be_nil
    end

    it "should parse the sample fields correctly" do
      match = @file_format.parse_line(@sample)
      match.should_not be_nil
    end

    it "should parse and convert the sample fields correctly" do
      @log_parser.parse_io(StringIO.new(@sample)) do |request|
        request[:remote_host].should    == '127.0.0.1'
        request[:timestamp].should      == 20091123214747
        request[:http_method].should    == 'GET'
        request[:path].should           == '/css/stylesheet.css'
        request[:http_version].should   == '1.1'
        request[:http_status].should    == 200
        request[:bytes_sent].should     == 3782
        request[:duration].should       == 0.0024
      end
    end

  end

end