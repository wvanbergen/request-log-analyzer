require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Tracker::Base, "API test" do

  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @tracker    = Class.new(RequestLogAnalyzer::Tracker::Base).new
    
    @summarizer = RequestLogAnalyzer::Aggregator::Summarizer.new(mock_source)
    @summarizer.trackers << @tracker
  end
  
  it "should receive :prepare when the summarizer is preparing" do
    @tracker.should_receive(:prepare).once    
    @summarizer.prepare
  end
  
  it "should receieve :finalize when the summarizer is finalizing" do
    @tracker.should_receive(:finalize).once    
    @summarizer.finalize    
  end
  
  it "should receive :update for every request for which should_update? returns true" do
    @tracker.should_receive(:should_update?).twice.and_return(true)
    @tracker.should_receive(:update).twice
    
    @summarizer.aggregate(spec_format.request(:field => 'value1'))
    @summarizer.aggregate(spec_format.request(:field => 'value2'))    
  end
  
  it "should not :update for every request for which should_update? returns false" do
    @tracker.should_receive(:should_update?).twice.and_return(false)
    @tracker.should_not_receive(:update)
    
    @summarizer.aggregate(spec_format.request(:field => 'value1'))
    @summarizer.aggregate(spec_format.request(:field => 'value2'))    
  end
  
  it "should receive :report when the summary report is being built" do
    @tracker.should_receive(:report).with(anything).once   
    @summarizer.report(mock_output) 
  end
  
end

describe RequestLogAnalyzer::Tracker::Timespan do

  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Timespan.new
    @tracker.prepare
  end

  it "should set the first request timestamp correctly" do
    @tracker.update(spec_format.request(:timestamp => 20090102000000))
    @tracker.update(spec_format.request(:timestamp => 20090101000000))    
    @tracker.update(spec_format.request(:timestamp => 20090103000000))        
    
    @tracker.first_timestamp.should == DateTime.parse('Januari 1, 2009 00:00:00')
  end

  it "should set the last request timestamp correctly" do
    @tracker.update(spec_format.request(:timestamp => 20090102000000))
    @tracker.update(spec_format.request(:timestamp => 20090101000000))    
    @tracker.update(spec_format.request(:timestamp => 20090103000000))        

    @tracker.last_timestamp.should == DateTime.parse('Januari 3, 2009 00:00:00')
  end
  
  it "should return the correct timespan in days when multiple requests are given" do
    @tracker.update(spec_format.request(:timestamp => 20090102000000))
    @tracker.update(spec_format.request(:timestamp => 20090101000000))    
    @tracker.update(spec_format.request(:timestamp => 20090103000000))  
    
    @tracker.timespan.should == 2          
  end

  it "should return a timespan of 0 days when only one timestamp is set" do
    @tracker.update(spec_format.request(:timestamp => 20090103000000))  
    @tracker.timespan.should == 0
  end

  it "should raise an error  when no timestamp is set" do
    lambda { @tracker.timespan }.should raise_error
  end
end

describe RequestLogAnalyzer::Tracker::Duration do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => :category)
    @tracker.prepare
  end
  
  it "should" do
    
  end
end
