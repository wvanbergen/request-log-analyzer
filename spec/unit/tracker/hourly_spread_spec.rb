require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::HourlySpread do

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::HourlySpread.new
    @tracker.prepare
  end

  it "should store timestamps correctly" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))        
    
    @tracker.request_time_graph[0].should eql(3)
  end

  it "should count the number of timestamps correctly" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))        
    @tracker.update(request(:timestamp => 20090103010000))        
    
    @tracker.total_requests.should eql(4)
  end

  it "should set the first request timestamp correctly" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))        
    
    @tracker.first_timestamp.should == DateTime.parse('Januari 1, 2009 00:00:00')
  end

  it "should set the last request timestamp correctly" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))        

    @tracker.last_timestamp.should == DateTime.parse('Januari 3, 2009 00:00:00')
  end

  it "should return the correct timespan in days when multiple requests are given" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))  
    
    @tracker.timespan.should == 2          
  end

end

describe RequestLogAnalyzer::Tracker::HourlySpread, 'reporting' do
 
  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::HourlySpread.new
    @tracker.prepare
  end

  it "should generate a report without errors when no request was tracked" do
    lambda { @tracker.report(mock_output) }.should_not raise_error
  end

  it "should generate a report without errors when multiple requests were tracked" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))    
    @tracker.update(request(:timestamp => 20090103000000))        
    @tracker.update(request(:timestamp => 20090103010000))
    lambda { @tracker.report(mock_output) }.should_not raise_error
  end
end