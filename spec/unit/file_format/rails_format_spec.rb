require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails do
  
  before(:each) do
    @log_parser = RequestLogAnalyzer::Source::LogParser.new(
          RequestLogAnalyzer::FileFormat.load(:rails), :parse_strategy => 'cautious')
  end
  
  it "should have a valid language definitions" do
    @log_parser.file_format.should be_valid
  end
  
  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:rails_1x), 'r')
    @log_parser.parse_io(io) do |request| 
      request.should be_kind_of(RequestLogAnalyzer::Request)
    end
    io.close
  end  
  
  it "should find 4 completed requests" do
    @log_parser.should_not_receive(:warn)  
    @log_parser.should_receive(:handle_request).exactly(4).times
    @log_parser.parse_file(log_fixture(:rails_1x))
  end  
  
  it "should parse a Rails 2.2 request properly" do
    @log_parser.should_not_receive(:warn)
    @log_parser.parse_file(log_fixture(:rails_22)) do |request|
      request.should =~ :processing
      request.should =~ :completed  
    
      request[:controller].should == 'PageController'
      request[:action].should     == 'demo'
      request[:url].should        == 'http://www.example.coml/demo'    
      request[:status].should     == 200
      request[:duration].should   == 0.614
      request[:db].should         == 0.031
      request[:view].should       == 0.120
    end
  end
  
  it "should parse a syslog file with prefix correctly" do
    @log_parser.should_not_receive(:warn)    
    @log_parser.parse_file(log_fixture(:syslog_1x)) do |request| 
      
      request.should be_completed
      
      request[:controller].should == 'EmployeeController'
      request[:action].should     == 'index'
      request[:url].should        == 'http://example.com/employee.xml'    
      request[:status].should     == 200
      request[:duration].should   == 0.21665
      request[:db].should         == 0.0
      request[:view].should       == 0.00926
    end
  end
  
  it "should parse cached requests" do
    @log_parser.should_not_receive(:warn)
    @log_parser.parse_file(log_fixture(:rails_22_cached)) do |request| 
      request.should be_completed
      request =~ :cache_hit
    end  
  end
  
  it "should detect unordered requests in the logs" do
    # No valid request should be found in cautious mode
    @log_parser.should_not_receive(:handle_request)
    # the first Processing-line will not give a warning, but the next one will
    @log_parser.should_receive(:warn).with(:unclosed_request, anything).once
    # Both Completed lines will give a warning
    @log_parser.should_receive(:warn).with(:no_current_request, anything).twice
    
    @log_parser.parse_file(log_fixture(:rails_unordered))
  end  
end

describe RequestLogAnalyzer::FileFormat::RailsDevelopment do
  
  before(:each) do
    @file_format = RequestLogAnalyzer::FileFormat.load(:rails_development)
    @request = @file_format.request
  end
  
  it "should have a valid language definitions" do
    @file_format.should be_valid
  end
  
  it "should have a different line definer than Rails" do
    rails = RequestLogAnalyzer::FileFormat.load(:rails)
    rails.class.line_definer.should_not == @file_format.class.line_definer
  end
  
  it "should parse a rendered line" do
    info = @file_format.line_definitions[:rendered].match_for("Rendered layouts/_footer (2.9ms)", @request)
    info[:render_file].should == 'layouts/_footer'
    info[:render_duration].should == 0.0029
  end
  
  it "should parse a query executed line with colors" do
    info = @file_format.line_definitions[:query_executed].match_for(" [4;36;1mUser Load (0.4ms)[0m   [0;1mSELECT * FROM `users` WHERE (`users`.`id` = 18205844) [0m", @request)
    info[:query_class].should == 'User'
    info[:query_duration].should == 0.0004
    info[:query_sql].should == 'SELECT * FROM users WHERE (users.id = :int)'
  end  
  
  it "should parse a query executed line without colors" do
    info = @file_format.line_definitions[:query_executed].match_for(" User Load (0.4ms)   SELECT * FROM `users` WHERE (`users`.`id` = 18205844) ", @request)
    info[:query_class].should == 'User'
    info[:query_duration].should == 0.0004
    info[:query_sql].should == 'SELECT * FROM users WHERE (users.id = :int)'
  end  
  
  it "should parse a cached query line with colors" do
    info = @file_format.line_definitions[:query_cached].match_for(' [4;35;1mCACHE (0.0ms)[0m   [0mSELECT * FROM `users` WHERE (`users`.`id` = 0) [0m', @request)
    info[:cached_duration].should == 0.0
    info[:cached_sql].should == 'SELECT * FROM users WHERE (users.id = :int)'   
  end
  
  it "should parse a cached query line without colors" do
    info = @file_format.line_definitions[:query_cached].match_for(' CACHE (0.0ms)   SELECT * FROM `users` WHERE (`users`.`id` = 0) ', @request)
    info[:cached_duration].should == 0.0
    info[:cached_sql].should == 'SELECT * FROM users WHERE (users.id = :int)'  
  end  
end