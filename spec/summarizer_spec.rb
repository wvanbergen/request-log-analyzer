require File.dirname(__FILE__) + '/spec_helper'
require 'request_log_analyzer/aggregator/summarizer'

describe RequestLogAnalyzer::Aggregator::Summarizer, :single_line do
  
  before(:each) do
    @summarizer =   RequestLogAnalyzer::Aggregator::Summarizer.new(TestFileFormat, :combined_requests => false)
    @summarizer.prepare
    
    @test_request_1 = RequestLogAnalyzer::Request.create(TestFileFormat, {:line_type => :first, :request_no => 564})
    @test_request_2 = RequestLogAnalyzer::Request.create(TestFileFormat, {:line_type => :test, :test_capture => 'awesome'})
    @test_request_3 = RequestLogAnalyzer::Request.create(TestFileFormat, {:line_type => :last, :request_no => 564})        
  end
  
  it "should include the file format Summarizer module" do
    metaclass = (class << @summarizer; self; end)
    metaclass.ancestors.should include(TestFileFormat::Summarizer)
    @summarizer.class.ancestors.should_not include(TestFileFormat::Summarizer)
  end
  
  it "should set the default bucket for a new line type" do
    @summarizer.should_receive(:default_bucket_content).once.and_return(:count => 0)
    @summarizer.aggregate(@test_request_1)
  end
  
  it "should request a bucket name for the hash" do
    @summarizer.should_receive(:bucket_for).with(@test_request_1).once.and_return('all')
    @summarizer.aggregate(@test_request_1)
  end  

  it "should register" do
    @summarizer.should_receive(:update_bucket).with(anything, @test_request_1).once
    @summarizer.aggregate(@test_request_1)
  end

  it "should have buckets for every line type on the first level" do
    @summarizer.aggregate(@test_request_1)
    @summarizer.aggregate(@test_request_2)    
    @summarizer.aggregate(@test_request_3)    
    @summarizer.buckets.should have(3).items
    @summarizer.buckets.should have_key(:first)
    @summarizer.buckets.should have_key(:test)
    @summarizer.buckets.should have_key(:last)    
  end
  
  it "should aggregate in the same bucket" do
    @summarizer.should_receive(:bucket_for).exactly(3).times.and_return('all')
    3.times { @summarizer.aggregate(@test_request_2) }
    @summarizer.buckets[:test].should have(1).items
  end

  it "should aggregate in different buckets based on" do
    4.times do |n|
      @summarizer.stub!(:bucket_for).and_return("bucket #{n % 2}") # buckets 1 and 2
      @summarizer.aggregate(@test_request_2)
    end
    @summarizer.buckets[:test].should have(2).items
  end
  
end

describe RequestLogAnalyzer::Aggregator::Summarizer, :combined_requests do
  
  before(:each) do
    @summarizer = RequestLogAnalyzer::Aggregator::Summarizer.new(TestFileFormat, :combined_requests => true)
    @summarizer.prepare
    
    @test_request = RequestLogAnalyzer::Request.create(TestFileFormat, 
          {:line_type => :first, :request_no => 564},
          {:line_type => :test, :test_capture => 'blug'},
          {:line_type => :last, :request_no => 564})
  end
  
  it "should include the file format Summarizer module" do
    metaclass = (class << @summarizer; self; end)
    metaclass.ancestors.should include(TestFileFormat::Summarizer)
    @summarizer.class.ancestors.should_not include(TestFileFormat::Summarizer)
  end
  
  it "should set the default bucket for a new line type" do
    @summarizer.should_receive(:default_bucket_content).once.and_return(:count => 0)
    @summarizer.aggregate(@test_request)
  end

  it "should register" do
    @summarizer.should_receive(:update_bucket).with(anything, @test_request).once
    @summarizer.aggregate(@test_request)
  end
  
  it "should aggregate in the same bucket" do
    3.times { @summarizer.aggregate(@test_request) }
    @summarizer.buckets.should have(1).items
  end

  it "should aggregate in the same bucket" do
    @summarizer.should_receive(:bucket_for).exactly(3).times.and_return('all')
    3.times { @summarizer.aggregate(@test_request) }
    @summarizer.buckets.should have(1).items
  end

  it "should aggregate in different buckets based on" do
    4.times do |n|
      @summarizer.stub!(:bucket_for).and_return("bucket #{n % 2}") # buckets 1 and 2
      @summarizer.aggregate(@test_request)
    end
    @summarizer.buckets.should have(2).items
  end
  
end