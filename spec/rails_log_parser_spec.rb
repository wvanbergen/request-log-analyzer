require File.dirname(__FILE__) + '/spec_helper'

require 'request_log_analyzer/file_format'
require 'request_log_analyzer/request'
require 'request_log_analyzer/log_parser'

describe RequestLogAnalyzer::LogParser, "Rails without combined requests" do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(:rails, :combined_requests => false)
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
    @log_parser.parse_file(log_fixture(:rails_1x)) { |request| requests << request }
    requests.length.should == 8
    requests.each { |r| r.should be_single_line }
    requests.select { |r| r.line_type == :started }.length.should == 4 
  end  
end


describe RequestLogAnalyzer::LogParser, "Rails with combined requests" do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(:rails, :combined_requests => true)
  end
  
  it "should have a valid language definitions" do
    @log_parser.should be_valid_language
  end
  
  it "should parse a Rails 2.2 request properly" do
    requests = []
    @log_parser.parse_file(log_fixture(:rails_22)) { |request| requests << request }
    requests.length.should == 1
    
    requests.first.should =~ :started
    requests.first.should =~ :completed  
    
    requests.first[:controller].should == 'PageController'
    requests.first[:action].should     == 'demo'
    requests.first[:url].should        == 'http://www.example.coml/demo'    
    requests.first[:status].should     == 200
    requests.first[:duration].should   == 0.614
    requests.first[:db].should         == 0.031
    requests.first[:view].should       == 0.120
  end
  
  it "should find 4 completed requests when lines are linked" do
    requests = []
    @log_parser.parse_file(log_fixture(:rails_1x)) do |request|
      request.should be_completed
      requests << request
    end
    requests.length.should == 4
  end

end