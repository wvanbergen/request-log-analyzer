require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/request_log_analyzer/filter/timespan'
require File.dirname(__FILE__) + '/../lib/request_log_analyzer/filter/field'

describe RequestLogAnalyzer::Filter::Timespan, 'both before and after'  do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(spec_format, :after => DateTime.parse('2009-01-01'), :before => DateTime.parse('2009-02-02'))
    @filter.prepare
  end
  
  it "should reject a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_nil
  end
  
  it "should reject a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_nil
  end
  
  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end
end

describe RequestLogAnalyzer::Filter::Timespan, 'only before'  do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(spec_format, :before => DateTime.parse('2009-02-02'))    
    @filter.prepare
  end
  
  it "should accept a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should_not be_nil
  end
  
  it "should reject a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_nil
  end
  
  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end   
end

describe RequestLogAnalyzer::Filter::Timespan, 'only after'  do  
  include RequestLogAnalyzerSpecHelper 
  
  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(spec_format, :after => DateTime.parse('2009-01-01'))
    @filter.prepare
  end
  
  it "should reject a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_nil
  end
  
  it "should accept a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should_not be_nil
  end
  
  it "should accept a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should_not be_nil
  end  
end

describe RequestLogAnalyzer::Filter::Field, 'string in accept mode' do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(spec_format, :field => :test, :value => 'test', :mode => :select)
    @filter.prepare
  end
  
  it "should reject a request if the field value does not match" do
    @filter.filter(request(:test => 'not test')).should be_nil
  end
  
  it "should reject a request if the field name does not match" do
    @filter.filter(request(:testing => 'test')).should be_nil
  end

  it "should accept a request if the both name and value match" do
    @filter.filter(request(:test => 'test')).should_not be_nil
  end 
    
  it "should accept a request if the value is not the first value" do
    @filter.filter(request([{:test => 'ignore'}, {:test => 'test'}])).should_not be_nil
  end  
end

describe RequestLogAnalyzer::Filter::Field, 'string in reject mode' do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(spec_format, :field => :test, :value => 'test', :mode => :reject)
    @filter.prepare
  end
  
  it "should accept a request if the field value does not match" do
    @filter.filter(request(:test => 'not test')).should_not be_nil
  end
  
  it "should accept a request if the field name does not match" do
    @filter.filter(request(:testing => 'test')).should_not be_nil
  end

  it "should reject a request if the both name and value match" do
    @filter.filter(request(:test => 'test')).should be_nil
  end 
    
  it "should reject a request if the value is not the first value" do
    @filter.filter(request([{:test => 'ignore'}, {:test => 'test'}])).should be_nil
  end  
end

describe RequestLogAnalyzer::Filter::Field, 'regexp in accept mode' do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(spec_format, :field => :test, :value => '/test/', :mode => :select)
    @filter.prepare
  end
  
  it "should reject a request if the field value does not match" do
    @filter.filter(request(:test => 'a working test')).should_not be_nil
  end
  
  it "should reject a request if the field name does not match" do
    @filter.filter(request(:testing => 'test')).should be_nil
  end

  it "should accept a request if the value is not the first value" do
    @filter.filter(request([{:test => 'ignore'}, {:test => 'testing 123'}])).should_not be_nil
  end  
end