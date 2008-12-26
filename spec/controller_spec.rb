require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Controller do

  include RequestLogAnalyzerSpecHelper

  it "should include the file format module" do
    controller = RequestLogAnalyzer::Controller.new(:rails)
    (class << controller; self; end).ancestors.include?(RequestLogAnalyzer::FileFormat::Rails)
  end

  it "should call the aggregators when run" do
    controller = RequestLogAnalyzer::Controller.new(:rails)
    controller << log_fixture(:rails_1x)
    
    mock_aggregator = mock('aggregator')
    mock_aggregator.should_receive(:prepare).once.ordered
    mock_aggregator.should_receive(:aggregate).with(an_instance_of(RequestLogAnalyzer::Request)).at_least(:twice).ordered
    mock_aggregator.should_receive(:finalize).once.ordered
    
    another_mock_aggregator = mock('another aggregator')
    another_mock_aggregator.should_receive(:prepare).once.ordered
    another_mock_aggregator.should_receive(:aggregate).with(an_instance_of(RequestLogAnalyzer::Request)).at_least(:twice).ordered
    another_mock_aggregator.should_receive(:finalize).once.ordered  
    
    controller.aggregators << mock_aggregator << another_mock_aggregator
    controller.run!
  end
  
end