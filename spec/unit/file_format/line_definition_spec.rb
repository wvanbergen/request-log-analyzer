require 'spec_helper'

describe RequestLogAnalyzer::LineDefinition do

  subject { RequestLogAnalyzer::LineDefinition.new(:test, {
      :teaser   => /Testing /,
      :regexp   => /Testing (\w+), tries\: (\d+)/,
      :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer }]
    })
  }

  describe '#matches' do

    it "should return false on an unmatching line" do
      subject.matches("nonmatching").should be_false
    end

    it "should return false when only the teaser matches" do
      subject.matches("Testing LineDefinition").should be_false
    end

    it "should parse a line and capture the expected values" do
      subject.matches("Testing LineDefinition, tries: 123").should == {:line_definition => subject, :captures => ['LineDefinition', '123'] }
    end

    it "should know which names it can capture" do
      subject.captures?(:what).should be_true
      subject.captures?(:tries).should be_true
      subject.captures?(:bogus).should be_false
    end
  end

  describe '#convert_captured_values' do
    let(:request) { mock('request', :convert_value => 'foo') }

    it "should call convert_value for every captured value" do
      request.should_receive(:convert_value).twice
      subject.convert_captured_values(['test', '123'], request)
    end

    it "should set the converted values" do
      subject.convert_captured_values(['test', '123'], request).should == {:what => 'foo', :tries => 'foo'}
    end

    context 'when using :provides option' do
      
      subject { RequestLogAnalyzer::LineDefinition.new(:test, 
          :regexp   => /Hash\: (\{.+\})/,
          :captures => [{ :name => :hash, :type => :hash, :provides => {:bar => :string}}]) 
      } 
      
      before do
        request.stub!(:convert_value).with("{:bar=>'baz'}", anything).and_return(:bar => 'baz')
        request.stub!(:convert_value).with('baz', anything).and_return('foo')
      end

      it "should call Request#convert_value for the initial hash and the value in the hash" do
        request.should_receive(:convert_value).with("{:bar=>'baz'}", anything).and_return(:bar => 'baz')
        request.should_receive(:convert_value).with("baz", anything)
        subject.convert_captured_values(["{:bar=>'baz'}"], request)
      end

      it "should return the converted hash" do
        subject.convert_captured_values(["{:bar=>'baz'}"], request).should include(:bar => 'foo')
      end
    end
  end
end
