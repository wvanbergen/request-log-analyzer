require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::Request, :incomplete_request do
  
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @incomplete_request = RequestLogAnalyzer::Request.new(spec_format)
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
  
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @completed_request = RequestLogAnalyzer::Request.new(spec_format)
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
  
end