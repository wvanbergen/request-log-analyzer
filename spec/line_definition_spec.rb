require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::LineDefinition, :parsing do
  
  before(:each) do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
      :teaser   => /Testing /,
      :regexp   => /Testing (\w+), tries\: (\d+)/,
      :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer }]
    })
  end
  
  it "should return false on an unmatching line" do
    (@line_definition =~ "nonmatching").should be_false
  end
  
  it "should return false when only the teaser matches" do
    (@line_definition =~ "Testing LineDefinition").should be_false  
  end
  
  it "should return a hash if the line matches" do
    (@line_definition =~ "Testing LineDefinition, tries: 123").should be_kind_of(Hash)
  end
  
  it "should return a hash with :captures set to an array" do
    hash = @line_definition.matches("Testing LineDefinition, tries: 123")
    hash[:captures][0].should == "LineDefinition"
    hash[:captures][1].should == "123"
  end
  
  it "should return a hash with :line_definition set" do
    @line_definition.matches("Testing LineDefinition, tries: 123")[:line_definition].should == @line_definition
  end
end

describe RequestLogAnalyzer::LineDefinition, :converting do

  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @file_format = spec_format
    @request = @file_format.request
  end
  
  it "should convert captures to a hash of converted values" do
    hash = @file_format.line_definitions[:first].convert_captured_values(["456"], @request)
    hash[:request_no].should == 456
  end

  it "should convert captures to a hash" do
    hash = @file_format.line_definitions[:test].convert_captured_values(["willem", nil], @request)
    hash[:test_capture].should == 'Testing is willem'
    hash[:duration].should be_nil
  end

  
end
