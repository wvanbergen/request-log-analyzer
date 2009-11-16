require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Count do

  context 'static category' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Count.new(:category => :category, :field => :blah)
      @tracker.prepare
    end

    it "should register a request in the right category" do
      @tracker.update(request(:category => 'a', :blah => 2))
      @tracker.categories.should include('a')
    end

    it "should register requests in the right category" do
      @tracker.update(request(:category => 'a', :blah => 2))
      @tracker.update(request(:category => 'b', :blah => 2))
      @tracker.update(request(:category => 'b', :blah => 2))

      @tracker.categories['a'][:sum].should == 2
      @tracker.categories['b'][:sum].should == 4
    end
  end
  

  context 'dynamic category' do
    before(:each) do
      @categorizer = Proc.new { |request| request[:duration] > 0.2 ? 'slow' : 'fast' }
      @tracker = RequestLogAnalyzer::Tracker::Count.new(:category => @categorizer, :field => :blah)
      @tracker.prepare
    end

    it "should use the categorizer to determine the right category" do
      @tracker.update(request(:category => 'a', :duration => 0.2, :blah => 2))
      @tracker.update(request(:category => 'b', :duration => 0.3, :blah => 2))
      @tracker.update(request(:category => 'b', :duration => 0.4, :blah => 2))

      @tracker.categories['fast'][:sum].should == 2
      @tracker.categories['slow'][:sum].should == 4
    end
  end

  describe '#report' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Count.new(:category => :category, :field => :blah)
      @tracker.prepare
    end

    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :blah => 2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :blah => 2))
      @tracker.update(request(:category => 'b', :blah => 2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end
  end

  describe '#to_yaml_object' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Count.new(:category => :category, :field => :blah)
      @tracker.prepare
    end

    it "should generate a YAML output" do
      @tracker.update(request(:category => 'a', :blah => 2))
      @tracker.update(request(:category => 'b', :blah => 3))
      @tracker.to_yaml_object.should == {"a"=>{:min=>2, :hits=>1, :max=>2, :mean=>2.0, :sum=>2, :sum_of_squares=>0.0}, "b"=>{:min=>3, :hits=>1, :max=>3, :mean=>3.0, :sum=>3, :sum_of_squares=>0.0}}
    end
  end
end
