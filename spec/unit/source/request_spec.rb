require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Request, :incomplete_request do
  
  before(:each) do
    @incomplete_request = testing_format.request
    @incomplete_request << { :line_type => :test, :lineno => 1, :test_capture => 'awesome!' }
  end
  
  it "should be single if only one line has been added" do
    @incomplete_request.should_not be_empty
  end
  
  it "should not be a completed request" do
    @incomplete_request.should_not be_completed
  end  
  
  it "should take the line type of the first line as global line_type" do
    @incomplete_request.lines[0][:line_type].should == :test
    @incomplete_request.should =~ :test
  end
  
  it "should return the first field value" do
    @incomplete_request[:test_capture].should == 'awesome!'
  end
  
  it "should return nil if no such field is present" do
    @incomplete_request[:nonexisting].should be_nil
  end
end  


describe RequestLogAnalyzer::Request, :completed_request do
  
  before(:each) do
    @completed_request = testing_format.request
    @completed_request << { :line_type => :first, :lineno =>  1, :name => 'first line!' }    
    @completed_request << { :line_type => :test,  :lineno =>  4, :test_capture => 'testing' }        
    @completed_request << { :line_type => :test,  :lineno =>  7, :test_capture => 'testing some more' }            
    @completed_request << { :line_type => :last,  :lineno => 10, :time => 0.03 }
  end
  
  it "should not be empty when multiple liness are added" do
    @completed_request.should_not be_empty
  end
  
  it "should be a completed request" do
    @completed_request.should be_completed
  end
  
  it "should recognize all line types" do
    [:first, :test, :last].each { |type| @completed_request.should =~ type }
  end
  
  it "should detect the correct field value" do
    @completed_request[:name].should == 'first line!'
    @completed_request[:time].should == 0.03
  end
  
  it "should detect the first matching field value" do  
    @completed_request.first(:test_capture).should == 'testing'
  end
  
  it "should detect the every matching field value" do  
    @completed_request.every(:test_capture).should == ['testing', "testing some more"]
  end
  
  it "should set the first_lineno for a request to the lowest lineno encountered" do
    @completed_request.first_lineno.should eql(1)
  end

  it "should set the last_lineno for a request to the highest encountered lineno" do
    @completed_request.last_lineno.should eql(10)
  end

  it "should not have a timestamp if no such field is captured" do
    @completed_request.timestamp.should be_nil
  end
  
end