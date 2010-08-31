require 'spec_helper'

describe RequestLogAnalyzer::Request do

  before(:each) do
    @request = testing_format.request
  end

  it "should be empty without any captured lines in it" do
    @request.should be_empty
  end

  context :incomplete do

    before(:each) do
      @request << { :line_type => :test, :lineno => 1, :test_capture => 'awesome!' }
    end

    it "should be single if only one line has been added" do
      @request.should_not be_empty
    end

    it "should not be a completed request" do
      @request.should_not be_completed
    end

    it "should take the line type of the first line as global line_type" do
      @request.lines[0][:line_type].should == :test
      @request.should =~ :test
    end

    it "should return the first field value" do
      @request[:test_capture].should == 'awesome!'
    end

    it "should return nil if no such field is present" do
      @request[:nonexisting].should be_nil
    end
  end

  context :completed do

    before(:each) do
      @request << { :line_type => :first, :lineno =>  1, :name => 'first line!' }
      @request << { :line_type => :test,  :lineno =>  4, :test_capture => 'testing' }
      @request << { :line_type => :test,  :lineno =>  7, :test_capture => 'testing some more' }
      @request << { :line_type => :last,  :lineno => 10, :time => 0.03 }
    end

    it "should not be empty when multiple liness are added" do
      @request.should_not be_empty
    end

    it "should be a completed request" do
      @request.should be_completed
    end

    it "should recognize all line types" do
      [:first, :test, :last].each { |type| @request.should =~ type }
    end

    it "should detect the correct field value" do
      @request[:name].should == 'first line!'
      @request[:time].should == 0.03
    end

    it "should detect the first matching field value" do
      @request.first(:test_capture).should == 'testing'
    end

    it "should detect the every matching field value" do
      @request.every(:test_capture).should == ['testing', "testing some more"]
    end

    it "should set the first_lineno for a request to the lowest lineno encountered" do
      @request.first_lineno.should eql(1)
    end

    it "should set the first_lineno for a request if a line with a lower lineno is added" do
      @request << { :line_type => :test, :lineno =>  0 }
      @request.first_lineno.should eql(0)
    end

    it "should set the last_lineno for a request to the highest encountered lineno" do
      @request.last_lineno.should eql(10)
    end

    it "should not set the last_lineno for a request if a line with a lower lineno is added" do
      @request << { :line_type => :test, :lineno =>  7 }
      @request.last_lineno.should eql(10)
    end

    it "should not have a timestamp if no such field is captured" do
      @request.timestamp.should be_nil
    end

    it "should set return a timestamp field if such a field is captured" do
      @request << { :line_type => :first, :lineno =>  1, :name => 'first line!', :timestamp => Time.now}
      @request.timestamp.should_not be_nil
    end
  end

  context 'single line' do
    # combined is both a header and a footer line
    before(:each) { @request << { :line_type => :combined, :lineno => 1 } }

    it "should be a completed request if the line is both header and footer" do
      @request.should be_completed
    end
  end
end
