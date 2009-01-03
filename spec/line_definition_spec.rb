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
  
  it "should return a hash with all captures set" do
    hash = @line_definition.matches("Testing LineDefinition, tries: 123")
    hash[:what].should == "LineDefinition"
    hash[:tries].should == 123
  end
  
  it "should return a hash with :line_type set" do
     @line_definition.matches("Testing LineDefinition, tries: 123")[:line_type].should == :test
   end
end

describe RequestLogAnalyzer::LineDefinition, :anonymizing_basics do
  before(:each) do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
      :teaser   => /Anonymize /,
      :regexp   => /Anonymize (\w+)!/,
      :captures => [{ :name => :what, :type => :string }]
    })
  end 
  
  it "should return nil if the teaser does not match" do
    @line_definition.anonymize("Nonsense").should be_nil
  end
  
  it "should return nil if no teaser exists and the regexp doesn't match" do
    line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize!/, :captures => []})

    line_definition.anonymize('nonsense').should be_nil
  end
  
  it "should return itself if only the teaser matches" do
    @line_definition.anonymize("Anonymize 456").should == "Anonymize 456"
  end  
  
  it "should return an empty string if the teaser matches and discard_teaser_lines is set" do
    @line_definition.anonymize("Anonymize 456", :discard_teaser_lines => true).should == ""
  end
  
  it "should return a string if the line matches" do
    @line_definition.anonymize("Anonymize anonymizing!").should be_kind_of(String)
  end
  
  it "should not anonymize :what" do
    @line_definition.anonymize("Anonymize anonymizing!").should == "Anonymize anonymizing!"
  end  
end

describe RequestLogAnalyzer::LineDefinition, :anonymizing_specifics do

  it "should anonymize completely if anonymize is true" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :string, :anonymize => true }]})

    @line_definition.anonymize("Anonymize 1.2.3.4!").should == "Anonymize ***!"
  end    
    
  it "should anonymize a URL" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :string, :anonymize => :url }]})
    
    @line_definition.anonymize("Anonymize https://www.not-anonymous.com/path/to/file.html!").should == "Anonymize http://example.com/path/to/file.html!"
  end
  
  it "should anonymize an IP address" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :string, :anonymize => :ip }]})
    
    @line_definition.anonymize("Anonymize 1.2.3.4!").should == "Anonymize 127.0.0.1!"
  end 
  
  it "should anonymize completely if the anonymizer is unknown" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :string, :anonymize => :unknown }]})

    @line_definition.anonymize("Anonymize 1.2.3.4!").should == "Anonymize ***!"
  end
  
  it "should anonymize an integer slightly" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :integer, :anonymize => :slightly }]})

    @line_definition.anonymize("Anonymize 1234!").should =~ /Anonymize \d{3,4}\!/
  end
  
  it "should anonymize an integer slightly" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :integer, :anonymize => :slightly }]})

    @line_definition.anonymize("Anonymize 1234!").should =~ /Anonymize \d{3,4}\!/
  end
  
  it "should anonymize an double slightly" do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
          :regexp => /Anonymize (.+)!/, :captures => [{ :name => :what, :type => :double, :anonymize => :slightly }]})

    @line_definition.anonymize("Anonymize 1.3!").should =~ /Anonymize 1\.\d+\!/
  end
   
end
