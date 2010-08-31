require 'spec_helper'

describe RequestLogAnalyzer::Tracker::Traffic do

  describe '#report' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:category => :category, :traffic => :traffic)
      @tracker.prepare
    end

    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.report(mock_output)
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.update(request(:category => 'b', :traffic => 2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end

  end
end
