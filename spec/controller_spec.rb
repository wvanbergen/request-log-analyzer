require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Controller do

  include RequestLogAnalyzerSpecHelper

  # it "should include the file format module" do
  #   controller = RequestLogAnalyzer::Controller.new(:rails)
  #   (class << controller; self; end).ancestors.include?(RequestLogAnalyzer::FileFormat::Rails)
  # end

  it "should call the aggregators when run" do
    
    mock_output = mock('output')
    mock_output.should_receive(:header)
    mock_output.should_receive(:footer)    
    
    file_format = RequestLogAnalyzer::FileFormat.load(:rails)
    source      = RequestLogAnalyzer::Source::LogParser.new(file_format, :source_files => log_fixture(:rails_1x))  
    controller  = RequestLogAnalyzer::Controller.new(source, :output => mock_output)
    
    mock_aggregator = mock('aggregator')
    mock_aggregator.should_receive(:prepare).once.ordered
    mock_aggregator.should_receive(:aggregate).with(an_instance_of(RequestLogAnalyzer::Request)).at_least(:twice).ordered
    mock_aggregator.should_receive(:finalize).once.ordered
    mock_aggregator.should_receive(:report).once.ordered
    
    another_mock_aggregator = mock('another aggregator')
    another_mock_aggregator.should_receive(:prepare).once.ordered
    another_mock_aggregator.should_receive(:aggregate).with(an_instance_of(RequestLogAnalyzer::Request)).at_least(:twice).ordered
    another_mock_aggregator.should_receive(:finalize).once.ordered  
    another_mock_aggregator.should_receive(:report).once.ordered  

    controller.aggregators << mock_aggregator << another_mock_aggregator
    controller.run!
  end
  
  it "should run well from the command line" do
    temp_file = "#{File.dirname(__FILE__)}/fixtures/temp.txt"
    system("#{File.dirname(__FILE__)}/../bin/request-log-analyzer #{log_fixture(:rails_1x)} > #{temp_file}").should be_true
    File.unlink(temp_file)
  end
  
end