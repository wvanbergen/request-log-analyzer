require File.dirname(__FILE__) + '/spec_helper'

require 'request_log_analyzer/file_format'
require 'request_log_analyzer/request'
require 'request_log_analyzer/log_parser'

describe RequestLogAnalyzer::LogParser, :line_by_line do
  
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(TestFileFormat)
  end
  
  it "should have line definitions" do
    @log_parser.file_format.line_definitions.should_not be_empty
  end

  it "should have a valid language" do
    @log_parser.should be_valid_language
  end
  
  it "should have include the language specific hooks in the instance, not in the class" do
    metaclass = (class << @log_parser; self; end)
    metaclass.ancestors.include?(TestFileFormat::LogParser).should be_true
    @log_parser.class.ancestors.include?(TestFileFormat::LogParser).should be_false
  end
  
  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:test_file_format), 'r')
    @log_parser.parse_io(io, :line_types => [:test_line]) do |request| 
      request.should be_kind_of(RequestLogAnalyzer::Request)
      request.should =~ :test_line
      request[:test_capture].should_not be_nil      
    end
    io.close
  end
  
  it "should parse a test file and find 2 test line matches" do
    matches = 0
    @log_parser.parse_file(log_fixture(:test_file_format), :line_types => [:test_line]) { |request| matches += 1 }
    matches.should eql(2)
  end
end

describe RequestLogAnalyzer::LogParser, :combibed do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(TestFileFormat, :combined_requests => true)
  end
  
  it "should have multiple line definitions" do
    @log_parser.file_format.line_definitions.length.should >= 2
  end  
  
  it "should have a valid language" do
    @log_parser.should be_valid_language
  end
  
  it "should parse a test file" do
    matches = []
    @log_parser.parse_file(log_fixture(:test_language_combined)) { |request| matches << request }  
    matches.length.should == 2
  end
end