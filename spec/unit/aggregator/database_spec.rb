require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Aggregator::Database do

  before(:all) do
    log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format)
    @database_inserter = RequestLogAnalyzer::Aggregator::Database.new(log_parser, :database => ':memory:')
    
    @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                          :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                            { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})                               
  end
  
  # The prepare method is called before the parsing starts. It should establish a connection
  # to a database that is suitable for inserting requests later on.
  describe '#prepare' do

    before(:each) do
      @database_inserter.stub!(:initialize_orm_module!)
      @database_inserter.stub!(:establish_database_connection!)
      @database_inserter.stub!(:create_database_schema!)
    end

    it 'should create the ORM mdoule in which the classes can be created' do
      @database_inserter.should_receive(:initialize_orm_module!)
      @database_inserter.prepare
    end

    it 'should establish the database connection' do
      @database_inserter.should_receive(:establish_database_connection!)
      @database_inserter.prepare
    end
    
    it 'should create the database schema during preparation' do
      @database_inserter.should_receive(:create_database_schema!)
      @database_inserter.prepare
    end
  end
  
  # The database inserter creates is own "Database" module within the file format 
  # class to create all the classes that are needed.
  describe '#initialize_orm_module!' do
    
    before(:all) { @database_inserter.send(:deinitialize_orm_module!) }
    after(:all)  { @database_inserter.send(:initialize_orm_module!) }
    
    before(:each) { @database_inserter.send(:initialize_orm_module!) }
    after(:each)  { @database_inserter.send(:deinitialize_orm_module!) }
    
    it "should create a Database module under the file format's class" do
      testing_format.class.should be_const_defined('Database')
    end
    
    it "should define a Base class in the Database module" do
      testing_format.class::Database.should be_const_defined('Base')
    end
    
    it "should create a ActiveRecord::Base class in the Database module" do
      testing_format.class::Database::Base.ancestors.should include(ActiveRecord::Base)
    end
    
  end
  
  # The create_database_table method should create a database table according to the line definition,
  # so that parsed lines can be stored in it later on.
  describe '#create_database_table' do
    
    before(:each) do
      @connection = mock_migrator
      @database_inserter.stub!(:connection).and_return(@connection)
    end
    
    it "should create a table based on the line type name" do
      @connection.should_receive(:create_table).with('test_lines')
      @database_inserter.send(:create_database_table, @line_definition)
    end    
    
    it "should create an index on the request_id field" do
      @connection.should_receive(:add_index).with('test_lines', [:request_id])
      @database_inserter.send(:create_database_table, @line_definition)
    end
    
    it "should create a request_id field to link the requests together" do
      @connection.table_creator.should_receive(:column).with(:request_id, :integer)
      @database_inserter.send(:create_database_table, @line_definition)
    end
    
    it "should create a lineno field to save the location of the line in the original file" do
      @connection.table_creator.should_receive(:column).with(:lineno, :integer)
      @database_inserter.send(:create_database_table, @line_definition)
    end
    
    it "should create a field of the correct type for every defined field" do
      @connection.table_creator.should_receive(:column).with(:what, :string)
      @connection.table_creator.should_receive(:column).with(:tries, :integer)
      # :hash capture type should map on a :text field type
      @connection.table_creator.should_receive(:column).with(:evaluated, :text) 
      @database_inserter.send(:create_database_table, @line_definition)      
    end
    
    it "should create a field of the correct type for every provided field" do
      # :duration capture type should map on a :double field type
      @connection.table_creator.should_receive(:column).with(:evaluated_field, :double) 
      @database_inserter.send(:create_database_table, @line_definition)   
    end
  end
  
  describe '#create_activerecord_class' do
    before(:each) do
      # Make sure the ORM module exists
      @database_inserter.send(:initialize_orm_module!)     
      
      # Mockthe request ORM class
      @request_class = mock('Request ActiveRecord::Base class')
      @request_class.stub!(:has_many)
      @database_inserter.stub!(:request_class).and_return(@request_class)
    end
    
    it "should register the constant for the line type AR class" do
      @database_inserter.send(:create_activerecord_class, @line_definition)
      @database_inserter.orm_module.const_defined?('TestLine').should be_true
    end
    
    it "should create a class that inherits from ActiveRecord::Base and the base class of the ORM module" do
      @database_inserter.send(:create_activerecord_class, @line_definition)
      @database_inserter.orm_module.const_get('TestLine').ancestors.should include(ActiveRecord::Base, @database_inserter.orm_module::Base)
    end    
    
    describe 'defining the new ORM class' do
      before(:each) do
        # Mock the newly created ORM class for the test_line
        @orm_class = mock('Line ActiveRecord::Base class')
        @orm_class.stub!(:belongs_to)
        @orm_class.stub!(:serialize)
        Class.stub!(:new).and_return(@orm_class)
      end

      it "should create a has_many relation on the Request class" do
        @request_class.should_receive(:has_many).with(:test_lines)
        @database_inserter.send(:create_activerecord_class, @line_definition)
      end
    
      it "should create a belongs_to relation to the request class" do
        @orm_class.should_receive(:belongs_to).with(:request)
        @database_inserter.send(:create_activerecord_class, @line_definition)            
      end
    
      it "should serialize the :evaluate field into the database" do
        @orm_class.should_receive(:serialize).with(:evaluated, Hash)
        @database_inserter.send(:create_activerecord_class, @line_definition)            
      end    
    end
  end
  
  describe '#create_database_schema!' do
  
    before(:each) do
      @line_type_cnt = testing_format.line_definitions.length

      @connection = mock_migrator
      @database_inserter.stub!(:connection).and_return(@connection)      
      
      # Stub the expected method calls for the preparation
      @database_inserter.stub!(:create_database_table)
      @database_inserter.stub!(:create_activerecord_class) 

      # Make sure the ORM module exists
      @database_inserter.send(:initialize_orm_module!)
    end

    it "should create a requests table to join request lines" do
      @connection.should_receive(:create_table).with("requests")
      @database_inserter.send :create_database_schema!
    end
        
    it "should create a Request class inheriting from ActiveRecord and the base class of the ORM module" do
      @database_inserter.send :create_database_schema!
      @database_inserter.request_class.ancestors.should include(ActiveRecord::Base, @database_inserter.orm_module::Base)
    end
    
    it "should create a warnings table for logging parse warnings" do
      @connection.should_receive(:create_table).with("warnings")
      @database_inserter.send :create_database_schema!
    end

    it "should create a Warnng class inheriting from ActiveRecord and the base class of the ORM module" do
      @database_inserter.send :create_database_schema!
      @database_inserter.warning_class.ancestors.should include(ActiveRecord::Base, @database_inserter.orm_module::Base)
    end
  
    it "should create a table for every line type" do
      @database_inserter.should_receive(:create_database_table).with(an_instance_of(RequestLogAnalyzer::LineDefinition)).exactly(@line_type_cnt).times
      @database_inserter.send :create_database_schema!
    end
    
    it "should create a ORM for every line type" do
      @database_inserter.should_receive(:create_activerecord_class).with(an_instance_of(RequestLogAnalyzer::LineDefinition)).exactly(@line_type_cnt).times
      @database_inserter.send :create_database_schema!
    end
  end
  
  describe '#aggregate' do
    before(:each) do
      @database_inserter.prepare

      @incomplete_request = testing_format.request( {:line_type => :first, :request_no => 564})
      @completed_request = testing_format.request( {:line_type => :first, :request_no  => 564}, 
                            {:line_type => :test, :test_capture => "awesome"},
                            {:line_type => :test, :test_capture => "indeed"}, 
                            {:line_type => :eval, :evaluated => { :greating => 'howdy'}, :greating => 'howdy' }, 
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
end
