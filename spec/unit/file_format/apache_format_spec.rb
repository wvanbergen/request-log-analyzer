require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Apache do

  describe '.access_line_definition' do
    before(:each) do
      @format_string   = '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"'
      @line_definition = RequestLogAnalyzer::FileFormat::Apache.access_line_definition(@format_string)
    end

    it "should create a Regexp to match the line" do
      @line_definition.regexp.should be_kind_of(Regexp)
    end

    it "should create a list of captures for the values in the lines" do
      @line_definition.captures.should be_kind_of(Array)
    end

    it "should make it a header line" do
      @line_definition.should be_header
    end

    it "should make it a footer line" do
      @line_definition.should be_footer
    end
  end

  describe '.create' do

    before(:each) do
      @format_string = '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"'
      @format = RequestLogAnalyzer::FileFormat::Apache.create(@format_string)
    end

    it "should create the :access line definition" do
      @format.should have_line_definition(:access).capturing(:timestamp, :ip_address, :http_method, :path, :http_version, :http_status)
    end

    it "should be a valid file format" do
      @format.should be_valid
    end
    
    it "should setup report trackers" do
      @format.report_trackers.should_not be_empty
    end
  end

  context 'log parsing' do

    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:apache)
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(@file_format)
      @sample = '69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"'
    end

    it "should have a valid language definitions" do
      @file_format.should be_valid
    end

    it "should parse a valid access log line" do
      @file_format.line_definitions[:access].matches(@sample).should be_kind_of(Hash)
    end

    it "should read the correct values from a valid access log line" do
      @log_parser.parse_io(@sample) do |request|
        request[:ip_address].should   == '69.41.0.45'
        request[:timestamp].should    == 20090902120240
        request[:http_status].should  == 404
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.1'
      end
    end
  
    it "should parse 5 request from fixture access log" do
      counter = mock('counter')
      counter.should_receive(:hit!).exactly(5).times
      @log_parser.parse_file(log_fixture(:apache)) { counter.hit! }
    end
  end
end

