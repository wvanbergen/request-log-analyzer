require 'spec_helper'

describe RequestLogAnalyzer::Filter::Timespan, 'both before and after'  do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(testing_format, :after => DateTime.parse('2009-01-01'), :before => DateTime.parse('2009-02-02'))
  end

  it "should reject a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_nil
  end

  it "should reject a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_nil
  end

  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end
end

describe RequestLogAnalyzer::Filter::Timespan, 'only before'  do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(testing_format, :before => DateTime.parse('2009-02-02'))
  end

  it "should accept a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should_not be_nil
  end

  it "should reject a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_nil
  end

  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end
end

describe RequestLogAnalyzer::Filter::Timespan, 'only after'  do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(testing_format, :after => DateTime.parse('2009-01-01'))
  end

  it "should reject a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_nil
  end

  it "should accept a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should_not be_nil
  end

  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end
end