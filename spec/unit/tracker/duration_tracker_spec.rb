require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Duration, 'static category' do
  
  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => :category)
    @tracker.prepare
  end

  it "should register a request in the right category" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.categories.keys.should include('a')
  end
 
  it "should register a hit in the right category" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.update(request(:category => 'b', :duration => 0.3))
    @tracker.update(request(:category => 'b', :duration => 0.4))
    
    @tracker.hits('a').should == 1
    @tracker.hits('b').should == 2
  end
  
  it "should sum the durations of the same category as cumulative duration" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.update(request(:category => 'b', :duration => 0.3))
    @tracker.update(request(:category => 'b', :duration => 0.4))      
    
    @tracker.cumulative_duration('a').should == 0.2
    @tracker.cumulative_duration('b').should == 0.7
  end
  
  it "should calculate the average duration correctly" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.update(request(:category => 'b', :duration => 0.3))
    @tracker.update(request(:category => 'b', :duration => 0.4))      
    
    @tracker.average_duration('a').should == 0.2
    @tracker.average_duration('b').should == 0.35
  end
  
  it "should set min and max duration correctly" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.update(request(:category => 'b', :duration => 0.3))
    @tracker.update(request(:category => 'b', :duration => 0.4))      
    
    @tracker.min_duration('b').should == 0.3
    @tracker.max_duration('b').should == 0.4
  end  
  
end

describe RequestLogAnalyzer::Tracker::Duration, 'dynamic category' do
  
  before(:each) do
    @categorizer = Proc.new { |request| request[:duration] > 0.2 ? 'slow' : 'fast' }
    @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => @categorizer)
    @tracker.prepare
  end
  
  it "should use the categorizer to determine the right category" do
    @tracker.update(request(:category => 'a', :duration => 0.2))
    @tracker.update(request(:category => 'b', :duration => 0.3))
    @tracker.update(request(:category => 'b', :duration => 0.4)) 
    
    @tracker.cumulative_duration('fast').should == 0.2
    @tracker.cumulative_duration('slow').should == 0.7     
  end
  
end

describe RequestLogAnalyzer::Tracker::Duration, 'reporting' do
 
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
end
