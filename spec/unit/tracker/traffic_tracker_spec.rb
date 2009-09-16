require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Tracker::Traffic do
  
  describe '#update' do
    
    context 'using a field-based category' do
      before(:each) do
        @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:traffic => :traffic, :category => :category)
        @tracker.prepare
      end
    
      it "should register a request in the right category" do
        @tracker.update(request(:category => 'a', :traffic => 200))
        @tracker.categories.should include('a')
      end
    
      it "should register a hit in the right category" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.hits('a').should == 1
        @tracker.hits('b').should == 2
      end
    
      it "should sum the traffics of the same category as cumulative traffic" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.cumulative_traffic('a').should == 1
        @tracker.cumulative_traffic('b').should == 5
      end
    
      it "should calculate the average traffic correctly" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.average_traffic('a').should == 1.0
        @tracker.average_traffic('b').should == 2.5
      end
    
      it "should set min and max traffic correctly" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.min_traffic('b').should == 2
        @tracker.max_traffic('b').should == 3
      end  
    
    end
  
    context 'using a dynamic category' do
      before(:each) do
        @categorizer = Proc.new { |request| request[:traffic] < 2 ? 'few' : 'lots' }
        @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:traffic => :traffic, :category => @categorizer)
        @tracker.prepare
      end
    
      it "should use the categorizer to determine the right category" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.categories.should include('few', 'lots')
      end
    
      it "should use the categorizer to aggregate the values correctly" do
        @tracker.update(request(:category => 'a', :traffic => 1))
        @tracker.update(request(:category => 'b', :traffic => 2))
        @tracker.update(request(:category => 'b', :traffic => 3))
      
        @tracker.max_traffic('few').should == 1
        @tracker.min_traffic('lots').should == 2
      end
    end
  end
  
  describe '#report' do
    before(:each) do
      @tracker = RequestLogAnalyzer::Tracker::Traffic.new(:category => :category, :traffic => :traffic)
      @tracker.prepare
    end
    
    it "should generate a report without errors when one category is present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.report(mock_output)
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end
  
    it "should generate a report without errors when no category is present" do
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end
  
    it "should generate a report without errors when multiple categories are present" do
      @tracker.update(request(:category => 'a', :traffic => 2))
      @tracker.update(request(:category => 'b', :traffic => 2))
      lambda { @tracker.report(mock_output) }.should_not raise_error
    end
    
  end
end
