require 'spec_helper'

describe RequestLogAnalyzer::Filter::Anonymize, 'anonymize request' do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Anonymize.new(testing_format)
  end

  it "should anonimize ip" do
    @filter.filter(request(:ip => '123.123.123.123'))[:ip].should_not eql('123.123.123.123')
  end

  it "should anonimize url" do
    @filter.filter(request(:url => 'https://test.mysite.com/employees'))[:url].should eql('http://example.com/employees')
  end

  it "should fuzz durations" do
    @filter.filter(request(:duration => 100))[:duration].should_not eql(100)
  end

end