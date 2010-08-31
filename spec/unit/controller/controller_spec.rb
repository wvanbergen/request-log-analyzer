require 'spec_helper'

describe RequestLogAnalyzer::Controller do

  it "should use a custom output generator correctly" do
    
    mock_output = mock('RequestLogAnalyzer::Output::Base')
    mock_output.stub!(:io).and_return(mock_io)
    mock_output.should_receive(:header)
    mock_output.should_receive(:footer)

    controller  = RequestLogAnalyzer::Controller.new(mock_source, :output => mock_output)

    controller.run!
  end

  it "should call aggregators correctly when run" do
    controller  = RequestLogAnalyzer::Controller.new(mock_source, :output => mock_output)
    
    mock_aggregator = mock('RequestLogAnalyzer::Aggregator::Base') 
    mock_aggregator.should_receive(:prepare).once.ordered
    mock_aggregator.should_receive(:aggregate).with(an_instance_of(testing_format.request_class)).twice.ordered
    mock_aggregator.should_receive(:finalize).once.ordered
    mock_aggregator.should_receive(:report).once.ordered
  
    controller.aggregators << mock_aggregator
    controller.run!
  end
  
  it "should call filters when run" do
    controller  = RequestLogAnalyzer::Controller.new(mock_source, :output => mock_output)
    
    mock_filter = mock('RequestLogAnalyzer::Filter::Base')
    mock_filter.should_receive(:filter).twice.and_return(nil)
    controller.should_receive(:aggregate_request).twice.and_return(nil)
    
    controller.filters << mock_filter
    controller.run!
  end
  
end
