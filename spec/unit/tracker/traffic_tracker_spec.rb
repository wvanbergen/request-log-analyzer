require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Traffic do

  context 'using a field-based category' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:traffic => :traffic, :category => :category)
      @tracker.prepare

      @tracker.update(request(:category => 'a', :traffic => 1))
      @tracker.update(request(:category => 'b', :traffic => 2))
      @tracker.update(request(:category => 'b', :traffic => 3))
    end

    it "should register a request in the right category using the category field" do
      @tracker.categories.should include('a', 'b')
    end

    it "should register requests under the correct category" do
      @tracker.hits('a').should == 1
      @tracker.hits('b').should == 2
    end
  end

  context 'using a dynamic category' do

    before(:each) do
      @categorizer = lambda { |request| request[:traffic] < 2 ? 'few' : 'lots' }
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:traffic => :traffic, :category => @categorizer)
      @tracker.prepare

      @tracker.update(request(:category => 'a', :traffic => 1))
      @tracker.update(request(:category => 'b', :traffic => 2))
      @tracker.update(request(:category => 'b', :traffic => 3))
    end

    it "should use the categorizer to determine the category" do
      @tracker.categories.should include('few', 'lots')
    end

    it "should register requests under the correct category using the categorizer" do
      @tracker.hits('few').should  == 1
      @tracker.hits('lots').should == 2
    end
  end

  describe '#update' do

    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:traffic => :traffic, :category => :category)
      @tracker.prepare

      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.update(request(:category => 'a', :traffic => 1))
      @tracker.update(request(:category => 'a', :traffic => 3))
    end

    it "should calculate the total traffic correctly" do
      @tracker.sum('a').should == 6
    end

    it "should calculate the traffic variance correctly" do
      @tracker.variance('a').should == 1.0
    end

    it "should calculate the traffic standard deviation correctly" do
      @tracker.stddev('a').should == 1.0
    end

    it "should calculate the average traffic correctly" do
      @tracker.mean('a').should == 2.0
    end

    it "should calculate the overall mean traffic correctly" do
      @tracker.mean_overall.should == 2.0
    end

    it "should set min and max traffic correctly" do
      @tracker.min('a').should == 1
      @tracker.max('a').should == 3
    end
  end

  describe '#report' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:category => :category, :traffic => :traffic)
      @tracker.prepare
    end

    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.report(mock_output)
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.update(request(:category => 'b', :traffic => 2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

  end
end
