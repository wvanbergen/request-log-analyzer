require File.dirname(__FILE__) + '/../../spec_helper'



describe RequestLogAnalyzer::Tracker::Duration do
  include RequestLogAnalyzer::Spec::Helper

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Duration.new(:duration => :duration, :category => :category)
    @tracker.prepare
  end
  
  it "should" do
    
  end
end
