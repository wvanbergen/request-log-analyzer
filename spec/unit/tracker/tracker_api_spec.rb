require 'spec_helper'

describe RequestLogAnalyzer::Tracker::Base do

  describe 'API' do

    before(:each) do
      @tracker    = Class.new(RequestLogAnalyzer::Tracker::Base).new

      @summarizer = RequestLogAnalyzer::Aggregator::Summarizer.new(mock_source)
      @summarizer.trackers << @tracker
    end

    it "should receive :prepare when the summarizer is preparing" do
      @tracker.should_receive(:prepare).once
      @summarizer.prepare
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
      m = mock_output
      m.should_receive(:report_tracker).with(@tracker)
      @summarizer.report(m)
    end

    it "should receieve :finalize when the summarizer is finalizing" do
      @tracker.should_receive(:finalize).once
      @summarizer.finalize
    end
  end

  describe '#should_update?' do
    before(:each) do
      @tracker_class = Class.new(RequestLogAnalyzer::Tracker::Base)
    end

    it "should return true by default, when no checks are installed" do
      tracker = @tracker_class.new
      tracker.should_update?(testing_format.request).should be_true
    end

    it "should return false if the line type is not in the request" do
      tracker = @tracker_class.new(:line_type => :not_there)
      tracker.should_update?(request(:line_type => :different)).should be_false
    end

    it "should return true if the line type is in the request" do
      tracker = @tracker_class.new(:line_type => :there)
      tracker.should_update?(request(:line_type => :there)).should be_true
    end

    it "should return true if a field name is given to :if and it is in the request" do
      tracker = @tracker_class.new(:if => :field)
      tracker.should_update?(request(:field => 'anything')).should be_true
    end

    it "should return false if a field name is given to :if and it is not the request" do
      tracker = @tracker_class.new(:if => :field)
      tracker.should_update?(request(:other_field => 'anything')).should be_false
    end

    it "should return false if a field name is given to :unless and it is in the request" do
      tracker = @tracker_class.new(:unless => :field)
      tracker.should_update?(request(:field => 'anything')).should be_false
    end

    it "should return true if a field name is given to :unless and it is not the request" do
      tracker = @tracker_class.new(:unless => :field)
      tracker.should_update?(request(:other_field => 'anything')).should be_true
    end

    it "should return the value of the block if one is given to the :if option" do
      tracker = @tracker_class.new(:if => lambda { |r| false } )
      tracker.should_update?(request(:field => 'anything')).should be_false
    end

    it "should return the inverse value of the block if one is given to the :if option" do
      tracker = @tracker_class.new(:unless => lambda { |r| false } )
      tracker.should_update?(request(:field => 'anything')).should be_true
    end

    it "should return false if any of the checks fail" do
      tracker = @tracker_class.new(:if => :field, :unless => lambda { |r| false }, :line_type => :not_present )
      tracker.should_update?(request(:line_type => :present, :field => 'anything')).should be_false
    end

    it "should return true if all of the checks succeed" do
      tracker = @tracker_class.new(:if => :field, :unless => lambda { |r| false }, :line_type => :present )
      tracker.should_update?(request(:line_type => :present, :field => 'anything')).should be_true
    end


  end

  describe '#to_yaml_object' do

    before(:each) do
      @tracker    = Class.new(RequestLogAnalyzer::Tracker::Base).new

      @summarizer = RequestLogAnalyzer::Aggregator::Summarizer.new(mock_source)
      @summarizer.trackers << @tracker
    end

    it "should receive :to_yaml object when finalizing" do
      @summarizer.options[:yaml] = temp_output_file(:yaml)
      @tracker.should_receive(:to_yaml_object).once
      @summarizer.to_yaml
    end
  end
end