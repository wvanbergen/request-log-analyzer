require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Apache do

  describe '.access_line_definition' do
    before(:each) do
      @format_string   = '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %T'
      @line_definition = RequestLogAnalyzer::FileFormat::Apache.access_line_definition(@format_string)
    end

    it "should create a Regexp to match the line" do
      @line_definition.regexp.should be_kind_of(Regexp)
    end

    it "should create a list of captures for the values in the lines" do
      @line_definition.captures.should have(12).items
    end

    it "should make it a header line" do
      @line_definition.should be_header
    end

    it "should make it a footer line" do
      @line_definition.should be_footer
    end

    it "should capture :duration" do
      @line_definition.captures?(:duration).should be_true
    end
  end

  describe '.create' do

    before(:each) do
      @format_string = '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"'
      @format = RequestLogAnalyzer::FileFormat::Apache.create(@format_string)
    end

    it "should create the :access line definition" do
      @format.should have_line_definition(:access).capturing(:timestamp, :remote_host, :bytes_sent, :http_method, :path, :http_version, :http_status)
    end

    it "should be a valid file format" do
      @format.should be_valid
    end

    it "should setup report trackers" do
      @format.report_trackers.should_not be_empty
    end
  end

  context '"Common" access log parsing' do
    before(:all) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:apache, :common)
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(@file_format)
      @sample_1 = '1.129.119.13 - - [08/Sep/2009:07:54:09 -0400] "GET /profile/18543424 HTTP/1.0" 200 8223'
      @sample_2 = '1.82.235.29 - - [08/Sep/2009:07:54:05 -0400] "GET /gallery/fresh?page=23&per_page=16 HTTP/1.1" 200 23414'
    end

    it "should have a valid language definitions" do
      @file_format.should be_valid
    end

    it "should parse a valid access log line" do
      @file_format.line_definitions[:access].matches(@sample_1).should be_kind_of(Hash)
    end

    it "should not parse a valid access log line" do
      @file_format.line_definitions[:access].matches('addasdsasadadssadasd').should be_false
    end

    it "should read the correct values from a valid HTTP/1.0 access log line" do
      @log_parser.parse_io(StringIO.new(@sample_1)) do |request|
        request[:remote_host].should  == '1.129.119.13'
        request[:timestamp].should    == 20090908075409
        request[:http_status].should  == 200
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.0'
        request[:bytes_sent].should   == 8223
        request[:user].should         == nil
      end
    end

    it "should read the correct values from a valid 200 access log line" do
      @log_parser.parse_io(StringIO.new(@sample_2)) do |request|
        request[:remote_host].should  == '1.82.235.29'
        request[:timestamp].should    == 20090908075405
        request[:http_status].should  == 200
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.1'
        request[:bytes_sent].should   == 23414
        request[:user].should         == nil
      end
    end

    it "should parse 10 request from fixture access log" do
      counter = mock('counter')
      counter.should_receive(:hit!).exactly(10).times
      @log_parser.parse_file(log_fixture(:apache_common)) { counter.hit! }
    end
  end

  context '"Rack" access log parser' do
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:rack)
      @log_parser  = RequestLogAnalyzer::Source::LogParser.new(@file_format)
      @sample_1 = '127.0.0.1 - - [16/Sep/2009 06:40:08] "GET /favicon.ico HTTP/1.1" 500 63183 0.0453'
    end

    it "should create a kind of an Apache file format" do
      @file_format.should be_kind_of(RequestLogAnalyzer::FileFormat::Apache)
    end

    it "should have a valid language definitions" do
      @file_format.should be_valid
    end

    it "should parse a valid access log line" do
      @file_format.line_definitions[:access].matches(@sample_1).should be_kind_of(Hash)
    end

    it "should not parse a valid access log line" do
      @file_format.line_definitions[:access].matches('addasdsasadadssadasd').should be_false
    end

    it "should read the correct values from a valid 404 access log line" do
      @log_parser.parse_io(StringIO.new(@sample_1)) do |request|
        request[:remote_host].should  == '127.0.0.1'
        request[:timestamp].should    == 20090916064008
        request[:http_status].should  == 500
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.1'
        request[:bytes_sent].should   == 63183
        request[:user].should         == nil
        request[:duration].should     == 0.0453
      end
    end
  end

  context '"Combined" access log parsing' do

    before(:all) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:apache, :combined)
      @log_parser  = RequestLogAnalyzer::Source::LogParser.new(@file_format)
      @sample_1 = '69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"'
      @sample_2 = '10.0.1.1 - - [02/Sep/2009:05:08:33 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"'
    end

    it "should have a valid language definitions" do
      @file_format.should be_valid
    end

    it "should parse a valid access log line" do
      @file_format.line_definitions[:access].matches(@sample_1).should be_kind_of(Hash)
    end

    it "should not parse a valid access log line" do
      @file_format.line_definitions[:access].matches('addasdsasadadssadasd').should be_false
    end

    it "should read the correct values from a valid 404 access log line" do
      @log_parser.parse_io(StringIO.new(@sample_1)) do |request|
        request[:remote_host].should  == '69.41.0.45'
        request[:timestamp].should    == 20090902120240
        request[:http_status].should  == 404
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.1'
        request[:bytes_sent].should   == 209
        request[:referer].should      == nil
        request[:user].should         == nil
        request[:user_agent].should   == 'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)'
      end
    end

    it "should read the correct values from a valid 200 access log line" do
      @log_parser.parse_io(StringIO.new(@sample_2)) do |request|
        request[:remote_host].should  == '10.0.1.1'
        request[:timestamp].should    == 20090902050833
        request[:http_status].should  == 200
        request[:http_method].should  == 'GET'
        request[:http_version].should == '1.1'
        request[:bytes_sent].should   == 30
        request[:referer].should      == nil
        request[:user].should         == nil
        request[:user_agent].should   == 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9'
      end
    end

    it "should parse 5 request from fixture access log" do
      counter = mock('counter')
      counter.should_receive(:hit!).exactly(5).times
      @log_parser.parse_file(log_fixture(:apache_combined)) { counter.hit! }
    end
  end
end

