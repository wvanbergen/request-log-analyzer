require 'spec_helper'

describe RequestLogAnalyzer::Tracker::Timespan do

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Timespan.new
    @tracker.prepare
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

  it "should return a timespan of 0 days when only one timestamp is set" do
    @tracker.update(request(:timestamp => 20090103000000))
    @tracker.timespan.should == 0
  end

  it "should raise an error when no timestamp is set" do
    lambda { @tracker.timespan }.should raise_error
  end
end

describe RequestLogAnalyzer::Tracker::Timespan, 'reporting' do

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::Timespan.new
    @tracker.prepare
  end
  
  it "should have a title" do
    @tracker.title.should_not eql("")
  end

  it "should generate a report without errors when no request was tracked" do
    lambda { @tracker.report(mock_output) }.should_not raise_error
  end

  it "should generate a report without errors when multiple requests were tracked" do
    @tracker.update(request(:category => 'a', :timestamp => 20090102000000))
    @tracker.update(request(:category => 'a', :timestamp => 20090101000000))
    @tracker.update(request(:category => 'a', :timestamp => 20090103000000))
    lambda { @tracker.report(mock_output) }.should_not raise_error
  end
  
  it "should generate a YAML output" do
    @tracker.update(request(:category => 'a', :timestamp => 20090102000000))
    @tracker.update(request(:category => 'a', :timestamp => 20090101000000))
    @tracker.update(request(:category => 'a', :timestamp => 20090103000000))
    @tracker.to_yaml_object.should == { :first => DateTime.parse('20090101000000'), :last => DateTime.parse('20090103000000')}
  end
  
end