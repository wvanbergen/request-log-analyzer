require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Base, "API test" do

  include RequestLogAnalyzer::Spec::Helper
  
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
    
    @summarizer.aggregate(testing_format.request(:field => 'value1'))
    @summarizer.aggregate(testing_format.request(:field => 'value2'))    
  end
  
  it "should not :update for every request for which should_update? returns false" do
    @tracker.should_receive(:should_update?).twice.and_return(false)
    @tracker.should_not_receive(:update)
    
    @summarizer.aggregate(testing_format.request(:field => 'value1'))
    @summarizer.aggregate(testing_format.request(:field => 'value2'))    
  end
  
  it "should receive :report when the summary report is being built" do
    @tracker.should_receive(:report).with(anything).once   
    @summarizer.report(mock_output) 
  end
  
end