require 'spec_helper'

describe RequestLogAnalyzer::Filter::Base, 'base filter' do

  before(:each) do
    @filter = RequestLogAnalyzer::Filter::Base.new(testing_format)
  end

  it "should return everything" do
    @filter.filter(request(:ip => '123.123.123.123'))[:ip].should eql('123.123.123.123')
  end

  it "should return nil on nil request" do
    @filter.filter(nil).should be_nil
  end

end