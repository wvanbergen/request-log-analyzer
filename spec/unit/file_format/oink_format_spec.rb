require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Oink do
  describe '.create' do

    context 'without providing a lines argument' do
      before(:each) { @oink = RequestLogAnalyzer::FileFormat.load(:oink) }

      it "should create a valid file format" do
        @oink.should be_valid
      end
      
      it "should parse :memory_usage line" do
        @oink.line_definitions.should include(:memory_usage)
      end

    end
  
  end
  
  describe '#parse_line' do
    before(:each) { @oink = RequestLogAnalyzer::FileFormat.load(:oink, :all) }
    
    it "should parse a :memory_usage line correctly" do
      line = 'Jun 18 11:27:36 derek rails[67783]: Memory usage: 714052 | PID: 67783'
      @oink.should parse_line(line).as(:memory_usage).and_capture(:pid => 67783, :memory => 714052)
    end
    
    it "should parse the PID from a :processing line correctly" do
      line = 'Aug 14 21:16:30 derek rails[67783]: Processing PeopleController#index (for 1.1.1.1 at 2008-08-14 21:16:30) [GET]'
      @oink.should parse_line(line).as(:processing).and_capture(:pid => 67783, :controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET', :ip => '1.1.1.1')
    end
  end
  
  describe '#parse_io' do
    context "Rails 2.2 style log" do
      before(:each) do
        @log_parser = RequestLogAnalyzer::Source::LogParser.new(
              RequestLogAnalyzer::FileFormat.load(:oink), :parse_strategy => 'cautious')
      end

      it "should parse requests" do
        request_counter.should_receive(:hit!).exactly(4).times
        
        @log_parser.parse_file(log_fixture(:oink_22)) do |request|
          request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails::Request) && request.completed?
        end
      end
      
      it "should not record :memory_diff on first request" do
        @log_parser.parse_file(log_fixture(:oink_22)) do |request|
          if @log_parser.parsed_requests == 1
            request[:memory_diff].should == nil
          end
        end
      end
      
      it "should record :memory_diff of 2nd tracked PID" do
        @log_parser.parse_file(log_fixture(:oink_22)) do |request|
          if @log_parser.parsed_requests == 3
            request[:memory_diff].should == 50000*1024
          end
        end
      end
      
      it "should record :memory_diff of 1st tracked PID" do
        @log_parser.parse_file(log_fixture(:oink_22)) do |request|
          if @log_parser.parsed_requests == 4
            request[:memory_diff].should == 30000*1024
          end
        end
      end
    end
    
    context 'Rails 2.2 style log w/failure' do
      before(:each) do
        @log_parser = RequestLogAnalyzer::Source::LogParser.new(
              RequestLogAnalyzer::FileFormat.load(:oink), :parse_strategy => 'cautious')
      end
      
      it "should parse requests" do
        request_counter.should_receive(:hit!).exactly(4).times
        
        @log_parser.parse_file(log_fixture(:oink_22_failure)) do |request|
          request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails::Request) && request.completed?
        end
      end
      
      it "should ignore memory changes when a failure occurs" do
        @log_parser.parse_file(log_fixture(:oink_22_failure)) do |request|
          if @log_parser.parsed_requests == 4
            request[:memory_diff].should == nil
          end
        end
      end
    end
  end
end
