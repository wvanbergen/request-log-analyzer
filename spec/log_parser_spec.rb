require File.dirname(__FILE__) + '/spec_helper'

require 'request_log_analyzer/file_format'
require 'request_log_analyzer/request'
require 'request_log_analyzer/log_parser'

module TestFileFormat
  
  LINE_DEFINITIONS = {
    :test => {
      :teaser => /testing /,
      :regexp => /testing is (\w+)/,
      :captures => [{:what => :string}]
    }
  }
end


describe RequestLogAnalyzer::LogParser do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::LogParser.new(TestFileFormat)
  end
  
  it "should have line definitions" do
    @log_parser.line_definitions.should_not be_empty
  end
  
  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:test), 'r')
    @log_parser.parse_io(io, :line_types => [:test]) do |request| 
      request.should be_kind_of(RequestLogAnalyzer::Request)
      request[:test].should_not be_nil
    end
    io.close
  end
  
  it "should parse a test file and find 2 test line matches" do
    matches = 0
    @log_parser.parse_file(log_fixture(:test), :line_types => [:test]) { |request| matches += 1 }
    matches.should == 2
  end
  
end