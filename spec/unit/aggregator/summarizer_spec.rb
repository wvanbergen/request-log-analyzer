require 'spec_helper'

describe RequestLogAnalyzer::Aggregator::Summarizer do

  before(:each) do
    @summarizer = RequestLogAnalyzer::Aggregator::Summarizer.new(mock_source, :output => mock_output)
    @summarizer.prepare
  end

  it "not raise exception when creating a report after aggregating multiple requests" do
    @summarizer.aggregate(request(:data => 'bluh1'))
    @summarizer.aggregate(request(:data => 'bluh2'))

    lambda { @summarizer.report(mock_output) }.should_not raise_error
  end

  it "not raise exception when creating a report after aggregating a single request" do
    @summarizer.aggregate(request(:data => 'bluh1'))
    lambda { @summarizer.report(mock_output) }.should_not raise_error
  end

  it "not raise exception when creating a report after aggregating no requests" do
    lambda { @summarizer.report(mock_output) }.should_not raise_error
  end

end
