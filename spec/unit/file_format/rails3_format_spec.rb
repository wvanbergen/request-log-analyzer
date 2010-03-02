require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:rails3).should be_valid
  end
  
  describe '#parse_line' do
    before(:each) { @file_format = RequestLogAnalyzer::FileFormat.load(:rails3) }

    it "should parse :started lines correctly" do
      line = 'Started GET "/queries" for 127.0.0.1 at 2010-02-25 16:15:18'
      @file_format.should parse_line(line).as(:started).and_capture(:method => 'GET', 
            :path => '/queries', :ip => '127.0.0.1', :timestamp => 20100225161518)
    end
    
    it "should parse :processing lines correctly" do
      line = ' Processing by QueriesController#index as HTML'
      @file_format.should parse_line(line).as(:processing).and_capture(
        :controller => 'QueriesController', :action => 'index', :format => 'HTML')
    end
    
    
    it "should parse :completed lines correctly" do
      line = 'Completed in 9ms (Views: 4.9ms | ActiveRecord: 0.5ms) with 200'
      @file_format.should parse_line(line).as(:completed).and_capture(
        :duration => 0.009, :status => 200)
    end
    
    it "should pase :failure lines correctly" do
      line = "ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/willem/Code/warehouse/app/views/queries/execute.csv.erb:"
      @file_format.should parse_line(line).as(:failure).and_capture(:line => 3, 
        :error   => 'ActionView::Template::Error', 
        :message => "undefined local variable or method `field' for #<Class>", 
        :file    => '/Users/willem/Code/warehouse/app/views/queries/execute.csv.erb')
    end
  end
  
  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:rails3))
    end
    
    it "should parse a successful request correctly" do
      request_counter.should_receive(:hit!).once
      @log_parser.should_not_receive(:warn)
      
      @log_parser.parse_file(log_fixture(:rails3_success)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails3::Request) && request.completed?
      end
    end
    
    it "should parse a failing request correctly" do
      request_counter.should_receive(:hit!).once
      @log_parser.should_not_receive(:warn)
      
      @log_parser.parse_file(log_fixture(:rails3_failure)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails3::Request) && request.completed?
      end
    end
  end
end