require 'spec_helper'

describe RequestLogAnalyzer::Filter::Field, 'string in accept mode' do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(testing_format, :field => :test, :value => 'test', :mode => :select)
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

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(testing_format, :field => :test, :value => 'test', :mode => :reject)
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

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Field.new(testing_format, :field => :test, :value => '/test/', :mode => :select)
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