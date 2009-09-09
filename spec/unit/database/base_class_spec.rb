require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Database::Base do
  
  describe '.subclass_from_line_definition' do
    before(:all) do
      @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                          :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                            { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})
    end
    
    before(:each) do
      @orm_class = mock('Line ActiveRecord::Base class')
      @orm_class.stub!(:set_table_name)
      @orm_class.stub!(:belongs_to)
      @orm_class.stub!(:serialize)
      Class.stub!(:new).with(RequestLogAnalyzer::Database::Base).and_return(@orm_class)
      
      @request_class = mock('Request ActiveRecord::Base class')
      @request_class.stub!(:has_many)
      @source_class = mock('Source ActiveRecord::Base class')
      @source_class.stub!(:has_many)      
      
      @database = mock_database
      @database.stub!(:request_class).and_return(@request_class)
      @database.stub!(:source_class).and_return(@source_class)
      RequestLogAnalyzer::Database::Base.stub!(:database).and_return(@database)
    end

    it "should create a new subclass using the Base class as parent" do
      Class.should_receive(:new).with(RequestLogAnalyzer::Database::Base).and_return(@orm_class)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should set the table name for the subclass" do
      @orm_class.should_receive(:set_table_name).with('test_lines')
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should set the :belongs_to relationship with the Request class" do
      @orm_class.should_receive(:belongs_to).with(:request)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should set a :has_many relationship in the request class" do
      @request_class.should_receive(:has_many).with(:test_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should set a :has_many relationship in the source class" do
      @source_class.should_receive(:has_many).with(:test_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should set the :belongs_to relationship with the Source class" do
      @orm_class.should_receive(:belongs_to).with(:source)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

    it "should serialize a complex field" do
      @orm_class.should_receive(:serialize).with(:evaluated, Hash)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition)
    end

  end

  describe '.subclass_from_table' do
    before(:each) do
      
      @request_class = mock('Request ActiveRecord::Base class')
      @request_class.stub!(:has_many)
      @source_class = mock('Source ActiveRecord::Base class')
      @source_class.stub!(:has_many)      
      
      @database = mock_database
      @database.stub!(:request_class).and_return(@request_class)
      @database.stub!(:source_class).and_return(@source_class)
      @database.connection.stub!(:table_exists?).and_return(true)
      RequestLogAnalyzer::Database::Base.stub!(:database).and_return(@database)
      
      @klass = mock('ActiveRecord ORM class')
      @klass.stub!(:column_names).and_return(['id', 'request_id', 'source_id', 'lineno', 'duration']) 
      @klass.stub!(:set_table_name)
      @klass.stub!(:belongs_to)
      Class.stub!(:new).with(RequestLogAnalyzer::Database::Base).and_return(@klass)
    end
    
    it "should set the table name" do
      @klass.should_receive(:set_table_name).with('completed_lines')
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines')
    end

    it "should create the :belongs_to relation to the request class" do
      @klass.should_receive(:belongs_to).with(:request)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines')
    end
    
    it "should create the :has_many relation in the request class" do
      @request_class.should_receive(:has_many).with(:completed_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines')
    end

    it "should create the :belongs_to relation to the source class" do
      @klass.should_receive(:belongs_to).with(:source)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines')
    end
    
    it "should create the :has_many relation in the request class" do
      @source_class.should_receive(:has_many).with(:completed_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines')
    end

  end
end

