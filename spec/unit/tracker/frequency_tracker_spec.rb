require 'spec_helper'

describe RequestLogAnalyzer::Tracker::Frequency do

  context 'static category' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Frequency.new(:category => :category)
      @tracker.prepare
    end

    it "should register a request in the right category" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      @tracker.categories.should include('a')
    end

    it "should register a request in the right category" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))

      @tracker.frequency('a').should == 1
      @tracker.frequency('b').should == 2
      @tracker.overall_frequency.should == 3
    end

    it "should sort correctly by frequency" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))

      @tracker.sorted_by_frequency.should == [['b', 2], ['a', 1]]
    end
  end
  

  context 'dynamic category' do
    before(:each) do
      @categorizer = Proc.new { |request| request[:duration] > 0.2 ? 'slow' : 'fast' }
      @tracker = RequestLogAnalyzer::Tracker::Frequency.new(:category => @categorizer)
      @tracker.prepare
    end

    it "should use the categorizer to determine the right category" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'b', :duration => 0.3))
      @tracker.update(request(:category => 'b', :duration => 0.4))

      @tracker.frequency('fast').should == 1
      @tracker.frequency('slow').should == 2
      @tracker.frequency('moderate').should == 0
    end
  end

  describe '#report' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Frequency.new(:category => :category)
      @tracker.prepare
    end

    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end
  end

  describe '#to_yaml_object' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Frequency.new(:category => :category)
      @tracker.prepare
    end

    it "should generate a YAML output" do
      @tracker.update(request(:category => 'a', :blah => 0.2))
      @tracker.update(request(:category => 'b', :blah => 0.2))
      @tracker.to_yaml_object.should == { "a" => 1, "b" => 1 }
    end
  end
end
