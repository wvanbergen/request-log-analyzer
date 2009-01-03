require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Request, :single_line do
  
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @single_line_request = RequestLogAnalyzer::Request.new(spec_format)
    @single_line_request << { :line_type => :test, :lineno => 1, :test_capture => 'awesome!' }
  end
  
  it "should include the file format module" do
    (class << @single_line_request; self; end).ancestors.include?(TestFileFormat)
  end  
  
  it "should be single if only one line has been added" do
    @single_line_request.should be_single_line
    @single_line_request.should_not be_empty
    @single_line_request.should_not be_combined    
  end
  
  it "should not be a completed request" do
    @single_line_request.should_not be_completed
  end  
  
  it "should take the line type of the first line as global line_type" do
    @single_line_request.line_type.should == :test
    @single_line_request.should =~ :test
  end
  
  it "should return the first field value" do
    @single_line_request[:test_capture].should == 'awesome!'
  end
  
  it "should return nil if no such field is present" do
    @single_line_request[:nonexisting].should be_nil
  end
end  


describe RequestLogAnalyzer::Request, :combined do
  
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @combined_request = RequestLogAnalyzer::Request.new(spec_format)
    @combined_request << { :line_type => :first, :lineno =>  1, :name => 'first line!' }    
    @combined_request << { :line_type => :test,  :lineno =>  4, :test_capture => 'testing' }        
    @combined_request << { :line_type => :test,  :lineno =>  7, :test_capture => 'testing some more' }            
    @combined_request << { :line_type => :last,  :lineno => 10, :time => 0.03 }
  end
  
  it "should be a combined request when more lines are added" do
    @combined_request.should be_combined
    @combined_request.should_not be_single_line
    @combined_request.should_not be_empty
  end
  
  it "should be a completed request" do
    @combined_request.should be_completed
  end
  
  it "should recognize all line types" do
    [:first, :test, :last].each { |type| @combined_request.should =~ type }
  end
  
  it "should detect the correct field value" do
    @combined_request[:name].should == 'first line!'
    @combined_request[:time].should == 0.03
  end
  
  it "should detect the first matching field value" do  
    @combined_request.first(:test_capture).should == 'testing'
  end
  
  it "should detect the every matching field value" do  
    @combined_request.every(:test_capture).should == ['testing', "testing some more"]
  end
  
end