require File.dirname(__FILE__) + '/spec_helper'

require 'request_log_analyzer/file_format'
require 'request_log_analyzer/request'
require 'request_log_analyzer/log_parser'

describe RequestLogAnalyzer::LogParser do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(:rails)
  end
  
  it "should have line definitions" do
    @log_parser.line_definitions.should_not be_empty
  end
  
  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:rails_1x), 'r')
    @log_parser.parse_io(io) do |request| 
      request.should be_kind_of(RequestLogAnalyzer::Request)
    end
    io.close
  end

  it "should find 8 requests when lines are not linked" do
    requests = []
    @log_parser.parse_file(log_fixture(:rails_1x), :combine => true) { |request| requests << request }
    requests.length.should == 8
    requests.each { |r| r.should be_single_line }
    requests.select { |r| r.line_type == :started }.length.should == 4 
  end
  
  it "should find 4 requests when lines are linked" do
    requests = []
    @log_parser.parse_file(log_fixture(:rails_1x), :combine => true) { |request| requests << request }
    requests.length.should == 4
  end

  
end