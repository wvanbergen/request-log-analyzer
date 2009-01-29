require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Aggregator::Database, "schema creation" do

  include RequestLogAnalyzer::Spec::Helper

  before(:each) do
    log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format)
    @database_inserter = RequestLogAnalyzer::Aggregator::Database.new(log_parser, :database => ':memory:')
  end

  
  it "should create the correct tables" do
    ActiveRecord::Migration.should_receive(:create_table).with("warnings")    
    ActiveRecord::Migration.should_receive(:create_table).with("requests")        
    ActiveRecord::Migration.should_receive(:create_table).with("first_lines")
    ActiveRecord::Migration.should_receive(:create_table).with("test_lines")        
    ActiveRecord::Migration.should_receive(:create_table).with("eval_lines")    
    ActiveRecord::Migration.should_receive(:create_table).with("last_lines")

    ActiveRecord::Migration.should_receive(:add_index).with("eval_lines",  [:request_id])
    ActiveRecord::Migration.should_receive(:add_index).with("first_lines", [:request_id])    
    ActiveRecord::Migration.should_receive(:add_index).with("test_lines",  [:request_id])
    ActiveRecord::Migration.should_receive(:add_index).with("last_lines",  [:request_id])

    @database_inserter.prepare
  end
  
  it "should create a default Request class" do
    @database_inserter.prepare
    TestingFormat::Database::Request.ancestors.should include(ActiveRecord::Base)
    TestingFormat::Database::Request.column_names.should include('first_lineno')
    TestingFormat::Database::Request.column_names.should include('last_lineno')    
  end
  
  it "should create associations for the default Request class" do
    @database_inserter.prepare
    @request = TestingFormat::Database::Request.new
    @request.should respond_to(:test_lines)
    @request.test_lines.should
  end
  
  it "should create the default table names" do
    @database_inserter.prepare
    @database_inserter.file_format.line_definitions.each do |name, definition|
      klass = TestingFormat::Database.const_get("#{name}_line".camelize)
      klass.column_names.should include('id')
      klass.column_names.should include('lineno')      
      klass.column_names.should include('request_id')      
    end
  end
  
  it "should create the correct fields in the table" do
    @database_inserter.prepare
    
    TestingFormat::Database::FirstLine.column_names.should include('request_no')
    TestingFormat::Database::LastLine.column_names.should include('request_no')
    TestingFormat::Database::TestLine.column_names.should include('test_capture')    
  end
  
  it "should create fields for provides" do
    @database_inserter.prepare
    TestingFormat::Database::EvalLine.column_names.should include('evaluated')    
    TestingFormat::Database::EvalLine.column_names.should include('greating')
    TestingFormat::Database::EvalLine.column_names.should include('what')    
  end
  
end

describe RequestLogAnalyzer::Aggregator::Database, "record insertion" do
  include RequestLogAnalyzer::Spec::Helper  
  
  before(:each) do
    log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format)    
    @database_inserter = RequestLogAnalyzer::Aggregator::Database.new(log_parser, :database => ':memory:')
    @database_inserter.prepare
        
    @incomplete_request = testing_format.request( {:line_type => :first, :request_no => 564})
    @completed_request = testing_format.request( {:line_type => :first, :request_no  => 564}, 
                          {:line_type => :test, :test_capture => "awesome"},
                          {:line_type => :test, :test_capture => "indeed"}, 
                          {:line_type => :eval, :evaluated => "{ 'greating' => 'howdy'}", :greating => 'howdy' }, 
                          {:line_type => :last, :request_no   => 564})    
  end
  
  it "should insert a record in the request table" do
    TestingFormat::Database::Request.count.should == 0
    @database_inserter.aggregate(@incomplete_request)
    TestingFormat::Database::Request.count.should == 1
  end
  
  it "should insert records in all relevant line tables" do
    @database_inserter.aggregate(@completed_request)
    request = TestingFormat::Database::Request.first
    request.should have(2).test_lines
    request.should have(1).first_lines  
    request.should have(1).eval_lines     
    request.should have(1).last_lines    
  end
  
  it "should log a warning in the warnings table" do
    TestingFormat::Database::Warning.should_receive(:create!).with(hash_including(:warning_type => 'test_warning'))
    @database_inserter.warning(:test_warning, "Testing the warning system", 12)
  end
  
end
