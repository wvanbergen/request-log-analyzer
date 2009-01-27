require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Controller do

  include RequestLogAnalyzerSpecHelper

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
    mock_aggregator.should_receive(:aggregate).with(an_instance_of(spec_format.request_class)).twice.ordered
    mock_aggregator.should_receive(:finalize).once.ordered
    mock_aggregator.should_receive(:report).once.ordered
  
    controller.aggregators << mock_aggregator
    controller.run!
  end
  
  it "should call filters when run" do
    controller  = RequestLogAnalyzer::Controller.new(mock_source, :output => mock_output)
    
    mock_filter = mock('RequestLogAnalyzer::Filter::Base')
    mock_filter.should_receive(:prepare).once.ordered
    mock_filter.should_receive(:filter).twice
    
    controller.should_not_receive(:aggregate_request)
    
    controller.filters << mock_filter
    controller.run!
  end
  
  it "should run well from the command line with the most important features" do
    
    temp_file = "#{File.dirname(__FILE__)}/fixtures/report.txt"
    temp_db   = "#{File.dirname(__FILE__)}/fixtures/output.db"
    binary = "#{File.dirname(__FILE__)}/../bin/request-log-analyzer"
  
    system("#{binary} #{log_fixture(:rails_1x)} --database #{temp_db} --select Controller PeopleController --file #{temp_file} > /dev/null").should be_true
  
    File.unlink(temp_file)
    File.unlink(temp_db)    
  end
  
end