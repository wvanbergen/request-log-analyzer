require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/../lib/request_log_analyzer/filter/timespan'

describe RequestLogAnalyzer::Filter::Timespan, 'both before and after'  do
  include RequestLogAnalyzerSpecHelper

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(TestFileFormat, :after => DateTime.parse('2009-01-01'), :before => DateTime.parse('2009-02-02'))
    @filter.prepare
  end
  
  it "should not yield a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_false
  end
  
  it "should not yield a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_false
  end
  
  it "should yield a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should be_true
  end
end

describe RequestLogAnalyzer::Filter::Timespan, 'only before'  do
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(TestFileFormat, :before => DateTime.parse('2009-02-02'))    
    @filter.prepare
  end
  
  it "should not yield a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_true
  end
  
  it "should not yield a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_false
  end
  
  it "should yield a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should be_true
  end  
 
end


describe RequestLogAnalyzer::Filter::Timespan, 'only after'  do  
  include RequestLogAnalyzerSpecHelper 
  
  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Timespan.new(TestFileFormat, :after => DateTime.parse('2009-01-01'))
    @filter.prepare
  end
  
  it "should not yield a request before the after date" do
    @filter.filter(request(:timestamp => 20081212000000)).should be_false
  end
  
  it "should not yield a request after the before date" do
    @filter.filter(request(:timestamp => 20090303000000)).should be_true
  end
  
  it "should yield a request between the after and before dates" do
    @filter.filter(request(:timestamp => 20090102000000)).should be_true
  end  
end

