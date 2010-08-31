require 'spec_helper'

describe RequestLogAnalyzer::Tracker::HourlySpread do

  before(:each) do
    @tracker = RequestLogAnalyzer::Tracker::HourlySpread.new
    @tracker.prepare
  end

  it "should store timestamps correctly" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))
    @tracker.update(request(:timestamp => 20090103000000))

    @tracker.hour_frequencies[0].should eql(3)
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
  
  it "should generate a YAML output" do
    @tracker.update(request(:timestamp => 20090102000000))
    @tracker.update(request(:timestamp => 20090101000000))
    @tracker.update(request(:timestamp => 20090103000000))
    @tracker.update(request(:timestamp => 20090103010000))
    @tracker.to_yaml_object.should == {"22:00 - 23:00"=>0, "9:00 - 10:00"=>0, "7:00 - 8:00"=>0, "2:00 - 3:00"=>0, "12:00 - 13:00"=>0, "11:00 - 12:00"=>0, "16:00 - 17:00"=>0, "15:00 - 16:00"=>0, "19:00 - 20:00"=>0, "3:00 - 4:00"=>0, "21:00 - 22:00"=>0, "20:00 - 21:00"=>0, "14:00 - 15:00"=>0, "13:00 - 14:00"=>0, "4:00 - 5:00"=>0, "10:00 - 11:00"=>0, "18:00 - 19:00"=>0, "17:00 - 18:00"=>0, "8:00 - 9:00"=>0, "6:00 - 7:00"=>0, "5:00 - 6:00"=>0, "1:00 - 2:00"=>1, "0:00 - 1:00"=>3, "23:00 - 24:00"=>0}
  end
end