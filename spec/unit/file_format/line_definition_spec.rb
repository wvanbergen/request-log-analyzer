require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::LineDefinition do

  before(:each) do
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, {
      :teaser   => /Testing /,
      :regexp   => /Testing (\w+), tries\: (\d+)/,
      :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer }]
    })
  end
  
  describe '#matches' do
  
    it "should return false on an unmatching line" do
      @line_definition.should_not parse("nonmatching")
    end
  
    it "should return false when only the teaser matches" do
      @line_definition.should_not parse("Testing LineDefinition")    
    end
  
    it "should parse a line and capture the expected values" do
      @line_definition.should parse("Testing LineDefinition, tries: 123").capturing('LineDefinition', '123')
    end
  end

  describe '#convert_captured_values' do

    before(:each) do
      @request = mock('request')
      @request.stub!(:convert_value).and_return('foo')
    end
    
    it "should call convert_value for every captured value" do
      @request.should_receive(:convert_value).twice
      @line_definition.convert_captured_values(['test', '123'], @request)
    end
    
    it "should set the converted values" do
      @line_definition.convert_captured_values(['test', '123'], @request).should == {:what => 'foo', :tries => 'foo'}
    end
    
    context 'when using :provides option' do
      before(:each) do
        @ld = RequestLogAnalyzer::LineDefinition.new(:test, :regexp   => /Hash\: (\{.+\})/, 
            :captures => [{ :name => :hash, :type => :hash, :provides => {:bar => :string}}])
            
        @request = mock('request')

        @request.stub!(:convert_value).with("{:bar=>'baz'}", anything).and_return(:bar => 'baz')
        @request.stub!(:convert_value).with('baz', anything).and_return('foo')
      end   
      
      it "should call Request#convert_value for the initial hash and the value in the hash" do
        @request.should_receive(:convert_value).with("{:bar=>'baz'}", anything).and_return(:bar => 'baz')
        @request.should_receive(:convert_value).with("baz", anything)
        @ld.convert_captured_values(["{:bar=>'baz'}"], @request)
      end
      
      it "should set the provides fields" do
        # The captures field must be set and converted as well
        @ld.convert_captured_values(["{:bar=>'baz'}"], @request)[:bar].should eql('foo')
      end      
    end
    
  end
end
