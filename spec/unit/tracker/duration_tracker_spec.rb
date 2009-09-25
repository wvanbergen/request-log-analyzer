require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Duration do

  context 'using a static category' do

    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => :category)
      @tracker.prepare
    end

    it "should create a category for every request using the category field" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.categories.keys.should include('a')
    end

    it "should register a request as hit in the right category" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'b', :duration => 0.3))
      @tracker.update(request(:category => 'b', :duration => 0.4))

      @tracker.hits('a').should == 1
      @tracker.hits('b').should == 2
    end
  end

  context 'using a dynamic category' do
    before(:each) do
      @categorizer = Proc.new { |request| request[:duration] > 0.2 ? 'slow' : 'fast' }
      @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => @categorizer)
      @tracker.prepare
    end

    it "should use the categorizer to determine the right category" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'b', :duration => 0.3))
      @tracker.update(request(:category => 'b', :duration => 0.4))

      @tracker.hits('fast').should == 1
      @tracker.hits('slow').should == 2
    end
  end

  describe '#update' do

    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => :category)
      @tracker.prepare

      @tracker.update(request(:category => 'a', :duration => 0.4))
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'a', :duration => 0.3))
    end

    it "should sum of the durations for a category correctly" do
      @tracker.sum('a').should be_close(0.9, 0.000001)
    end

    it "should overall sum of the durations correctly" do
      @tracker.sum_overall.should be_close(0.9, 0.000001)
    end

    it "should keep track of the minimum and maximum duration" do
      @tracker.min('a').should == 0.2
      @tracker.max('a').should == 0.4
    end

    it "should calculate the mean duration correctly" do
      @tracker.mean('a').should be_close(0.3, 0.000001)
    end

    it "should calculate the overall mean duration correctly" do
      @tracker.mean_overall.should be_close(0.3, 0.000001)
    end

    it "should calculate the duration variance correctly" do
      @tracker.variance('a').should be_close(0.01, 0.000001)
    end

    it "should calculate the duration standard deviation correctly" do
      @tracker.stddev('a').should be_close(0.1,  0.000001)
    end
  end

  describe '#report' do

    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Duration.new(:category => :category, :duration => :duration)
      @tracker.prepare
    end

    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'b', :duration => 0.2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a YAML output" do
      @tracker.update(request(:category => 'a', :duration => 0.2))
      @tracker.update(request(:category => 'b', :duration => 0.2))
      @tracker.to_yaml_object.should == {"a"=>{:hits=>1, :min=>0.2, :mean=>0.2, :max=>0.2, :sum_of_squares=>0.0, :sum=>0.2}, "b"=>{:hits=>1, :min=>0.2, :mean=>0.2, :max=>0.2, :sum_of_squares=>0.0, :sum=>0.2}}
    end
  end
  
  describe '#display_value' do
    before(:each) { @tracker = RequestLogAnalyzer::Tracker::Duration.new(:category => :category, :duration => :duration) }
    
    it "should only display seconds when time < 60" do
      @tracker.display_value(33.12).should == '33.12s'
    end

    it "should display minutes and wholeseconds when time > 60" do
      @tracker.display_value(63.12).should == '1m03s'
    end

    it "should display minutes and wholeseconds when time > 60" do
      @tracker.display_value(3601.12).should == '1h00m01s'
    end

  end
end
