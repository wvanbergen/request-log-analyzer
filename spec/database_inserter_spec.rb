require File.dirname(__FILE__) + '/spec_helper'
require 'request_log_analyzer/aggregator/database'


describe RequestLogAnalyzer::Aggregator::Database, "schema creation" do

  TEST_DATABASE_FILE = File.dirname(__FILE__) + "/fixtures/requests.db"
  include RequestLogAnalyzerSpecHelper
  
  before(:each) do
    log_parser = RequestLogAnalyzer::LogParser.new(spec_format)
    @database_inserter = RequestLogAnalyzer::Aggregator::Database.new(log_parser, :database => TEST_DATABASE_FILE)
  end
  
  after(:each) do
    File.unlink(TEST_DATABASE_FILE) if File.exist?(TEST_DATABASE_FILE)
  end
  
  it "should create the correct tables" do
    ActiveRecord::Migration.should_receive(:create_table).with("warnings")    
    ActiveRecord::Migration.should_receive(:create_table).with("requests")        
    ActiveRecord::Migration.should_receive(:create_table).with("first_lines")
    ActiveRecord::Migration.should_receive(:create_table).with("test_lines")        
    ActiveRecord::Migration.should_receive(:create_table).with("last_lines")    
    @database_inserter.prepare
  end
  
  it "should create a default Request class" do
    @database_inserter.prepare
    SpecFormat::Database::Request.ancestors.should include(ActiveRecord::Base)
    SpecFormat::Database::Request.column_names.should include('first_lineno')
    SpecFormat::Database::Request.column_names.should include('last_lineno')    
  end
  
  it "should create associations for the default Request class" do
    @database_inserter.prepare
    @request = SpecFormat::Database::Request.new
    @request.should respond_to(:test_lines)
    @request.test_lines.should
  end
  
  it "should create the default table names" do
    @database_inserter.prepare
    @database_inserter.file_format.line_definitions.each do |name, definition|
      klass = SpecFormat::Database.const_get("#{name}_line".camelize)
      klass.column_names.should include('id')
      klass.column_names.should include('lineno')      
      klass.column_names.should include('request_id')      
    end
  end
  
  it "should create the correct fields in the table" do
    @database_inserter.prepare
    
    SpecFormat::Database::FirstLine.column_names.should include('request_no')
    SpecFormat::Database::LastLine.column_names.should include('request_no')
    SpecFormat::Database::TestLine.column_names.should include('test_capture')    
  end
  
end

describe RequestLogAnalyzer::Aggregator::Database, "record insertion" do
  include RequestLogAnalyzerSpecHelper  
  
  before(:each) do
    log_parser = RequestLogAnalyzer::LogParser.new(spec_format)    
    @database_inserter = RequestLogAnalyzer::Aggregator::Database.new(log_parser, :database => TEST_DATABASE_FILE)
    @database_inserter.prepare
        
    @incomplete_request = RequestLogAnalyzer::Request.create(spec_format, {:line_type => :first, :request_no => 564})
    @completed_request = RequestLogAnalyzer::Request.create(spec_format, 
                          {:line_type => :first, :request_no  => 564},
                          {:line_type => :test, :test_capture => "awesome"},
                          {:line_type => :test, :test_capture => "indeed"},                                                    
                          {:line_type => :last, :request_no   => 564})    
  end
  
  after(:each) do
    File.unlink(TEST_DATABASE_FILE) if File.exist?(TEST_DATABASE_FILE)
  end 
  
  it "should insert a record in the request table" do
    SpecFormat::Database::Request.count.should == 0
    @database_inserter.aggregate(@incomplete_request)
    SpecFormat::Database::Request.count.should == 1
  end
  
  it "should insert records in all relevant line tables" do
    @database_inserter.aggregate(@completed_request)
    request = SpecFormat::Database::Request.first
    request.should have(2).test_lines
    request.should have(1).first_lines  
    request.should have(1).last_lines    
  end
  
  it "should log a warning in the warnings table" do
    SpecFormat::Database::Warning.should_receive(:create!).with(hash_including(:warning_type => 'test_warning'))
    @database_inserter.warning(:test_warning, "Testing the warning system", 12)
  end
  
end
