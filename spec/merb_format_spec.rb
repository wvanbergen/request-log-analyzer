require File.dirname(__FILE__) + '/spec_helper'

require 'request_log_analyzer/file_format'
require 'request_log_analyzer/request'
require 'request_log_analyzer/log_parser'

describe RequestLogAnalyzer::LogParser, "Merb without combined requests" do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(:merb, :combined_requests => false)
  end
  
  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:merb), 'r')
    @log_parser.parse_io(io) do |request| 
      request.should be_kind_of(RequestLogAnalyzer::Request)
      request.should be_single_line
    end
    io.close
  end

  it "should find 33 requests lines when lines are not linked" do
    requests = []
    @log_parser.parse_file(log_fixture(:merb)) { |request| requests << request }
    
    requests.length.should == 33
    requests.each { |r| r.should be_single_line }
    requests.select { |r| r.line_type == :started }.length.should == 11 
  end  
end


describe RequestLogAnalyzer::LogParser, "Merb with combined requests" do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(:merb, :combined_requests => true)
  end
  
  it "should have a valid language definitions" do
    @log_parser.should be_valid_language
  end
  
  it "should find 4 completed requests when lines are linked" do
    requests = []
    @log_parser.parse_file(log_fixture(:merb)) do |request|
      request.should be_completed
      requests << request
    end
    requests.length.should == 11
  end
  
  it "should parse all details from a request correctly" do
    request = nil
    @log_parser.parse_file(log_fixture(:merb)) { |found_request| request ||= found_request }
    
    request.should be_completed
    request[:timestamp].should == 'Fri Aug 29 11:10:23 +0200 2008'
    request[:dispatch_time].should == 0.243424
    request[:after_filters_time].should == 6.9e-05
    request[:before_filters_time].should == 0.213213
    request[:action_time].should == 0.241652
  end
end