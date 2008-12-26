require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::FileFormat::LineDefinition do
  
  before(:each) do
    @line_definition = RequestLogAnalyzer::FileFormat::LineDefinition.new(:test, {
      :teaser   => /Testing /,
      :regexp   => /Testing (\w+), tries\: (\d+)/,
      :captures => [{:what => :string}, {:tries => :integer}]
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
  
  it "should return a hash with all captures set" do
    hash = @line_definition.matches("Testing LineDefinition, tries: 123")
    hash[:what].should == "LineDefinition"
    hash[:tries].should == 123
  end
  
  it "should return a hash with :line_type set" do
     @line_definition.matches("Testing LineDefinition, tries: 123")[:line_type].should == :test
   end
end