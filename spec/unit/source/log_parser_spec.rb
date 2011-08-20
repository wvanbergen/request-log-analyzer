require 'spec_helper'

describe RequestLogAnalyzer::Source::LogParser do
  describe 'parsing request' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format)
    end

    it "should have multiple line definitions" do
      @log_parser.file_format.line_definitions.length.should >= 2
    end

    it "should have a valid language" do
      @log_parser.file_format.should be_well_formed
    end

    it "should set the :source for every parsed line" do
      @log_parser.parse_file(log_fixture(:rails_22)) do |request|
        request.lines.all? { |line| line[:source] == log_fixture(:rails_22) }.should be_true
      end
    end

    it "should set the :lineno for every parsed line" do
      @log_parser.parse_file(log_fixture(:rails_22)) do |request|
        request.lines.all? { |line| line.has_key?(:lineno) }.should be_true
      end
    end

    it "should parse more lines than requests" do
      @log_parser.should_receive(:handle_request).with(an_instance_of(TestingFormat::Request)).twice
      @log_parser.parse_file(log_fixture(:test_language_combined))
      @log_parser.parsed_lines.should > 2
    end

    it "should parse requests spanned over multiple files" do
      @log_parser.should_receive(:handle_request).with(an_instance_of(TestingFormat::Request)).once
      @log_parser.parse_files([log_fixture(:multiple_files_1), log_fixture(:multiple_files_2)])
    end

    it "should parse all request values when spanned over multiple files" do
      @log_parser.parse_files([log_fixture(:multiple_files_1), log_fixture(:multiple_files_2)]) do |request|
        request.lines.should have(4).items
        request[:request_no].should == 1
        request[:test_capture].should == "Testing is amazing" # Note the custom converter
      end
    end

    it "should parse a stream and find valid requests" do
      io = File.new(log_fixture(:test_file_format), 'rb')
      @log_parser.parse_io(io) do |request|
        request.should be_kind_of(RequestLogAnalyzer::Request)
        request.should =~ :test
        request[:test_capture].should_not be_nil
      end
      io.close
    end

    it "should parse a request that only consists of one line" do
      @log_parser.parse_file(log_fixture(:header_and_footer))
      @log_parser.parsed_requests.should == 2
    end
  end

  describe 'parse warnings' do

    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format, :parse_strategy => 'cautious')
    end

    it "should warn about teaser matching problems" do
      @log_parser.should_receive(:warn).with(:teaser_check_failed, anything).exactly(5).times
      @log_parser.parse_file(log_fixture(:test_file_format))
    end

    it "should warn about unmatching request headers and footers" do
      @log_parser.should_receive(:warn).with(:unclosed_request, anything).at_least(1).times
      @log_parser.should_receive(:warn).with(:no_current_request, anything).at_least(1).times
      @log_parser.should_not_receive(:handle_request)
      @log_parser.parse_file(log_fixture(:test_order))
    end
  end

  describe 'log file decompression' do

    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat::Rails.create)
    end

    if `which gunzip` != ""
      it "should parse a rails gzipped log file" do
        @log_parser.should_receive(:handle_request).once
        @log_parser.parse_file(log_fixture(:decompression, "log.gz"))
        @log_parser.parsed_lines.should > 0
      end

      it "should parse a rails tar gzipped log folder" do
        @log_parser.should_receive(:handle_request).twice
        @log_parser.parse_file(log_fixture(:decompression, "tar.gz"))
        @log_parser.parsed_lines.should > 1
      end
    end

    if `which bunzip2` != ""
      it "should parse a rails tar gzipped log folder" do
        @log_parser.should_receive(:handle_request).twice
        @log_parser.parse_file(log_fixture(:decompression, "tgz"))
        @log_parser.parsed_lines.should > 1
      end

      it "should parse a rails bz2 zipped log file" do
        @log_parser.should_receive(:handle_request).once
        @log_parser.parse_file(log_fixture(:decompression, "log.bz2"))
        @log_parser.parsed_lines.should > 0
      end
    end
  
    if `which unzip` != ""
      it "should parse a rails zipped log file" do
        @log_parser.should_receive(:handle_request).once
        @log_parser.parse_file(log_fixture(:decompression, "log.zip"))
        @log_parser.parsed_lines.should > 0
      end
    end
  end
end