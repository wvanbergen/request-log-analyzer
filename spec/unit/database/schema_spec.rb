require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::Database do
  
  describe '#create_database_schema!' do

    before(:all) do
      @database = RequestLogAnalyzer::Database.new(testing_format, nil)
    end

    before(:each) do
      @connection = mock_connection
      @database.stub!(:connection).and_return(@connection)

      # Stub the expected method calls for the preparation, these will be tested separately
      @database.stub!(:create_database_table)
      @database.stub!(:create_activerecord_class) 

    end

    it "should create a requests table to join request lines" do
      @connection.should_receive(:create_table).with(:requests)
      @database.send :create_database_schema!
    end
    
    it "should create a Request class inheriting from ActiveRecord and the base class of the ORM module" do
      @database.send :create_database_schema!
      @database.request_class.ancestors.should include(ActiveRecord::Base, @database.orm_module::Base)
    end

    it "should create a warnings table for logging parse warnings" do
      @connection.should_receive(:create_table).with(:warnings)
      @database.send :create_database_schema!
    end

    it "should create a Warning class inheriting from ActiveRecord and the base class of the ORM module" do
      @database.send :create_database_schema!
      @database.warning_class.ancestors.should include(ActiveRecord::Base, @database.orm_module::Base)
    end

    it "should create a sources table to track parsed files" do
      @connection.should_receive(:create_table).with(:sources)
      @database.send :create_database_schema!
    end    

    it "should create a Source ORM class" do
      @database.send :create_database_schema!
      @database.orm_module::Source.ancestors.should include(ActiveRecord::Base, @database.orm_module::Base)
    end

    it "should create a table for every line type" do
      @database.should_receive(:create_database_table).with(an_instance_of(RequestLogAnalyzer::LineDefinition)).exactly(testing_format.line_definitions.length).times
      @database.send :create_database_schema!
    end

    it "should create a ORM for every line type" do
      @database.should_receive(:create_activerecord_class).with(an_instance_of(RequestLogAnalyzer::LineDefinition)).exactly(testing_format.line_definitions.length).times
      @database.send :create_database_schema!
    end
  end
  
  describe '#create_activerecord_class' do
    
    before(:all) do
      @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                            :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                              { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})    
    end

    before(:each) do
      
      @database = RequestLogAnalyzer::Database.new(testing_format, nil)
      @database.remove_orm_classes!
      
      @connection = mock_connection
      @database.stub!(:connection).and_return(@connection)
      
      # Mock the request ORM class
      @request_class = mock('Request ActiveRecord::Base class')
      @request_class.stub!(:has_many)
      
      @source_class = mock('Source ActiveRecord::Base class')
      @source_class.stub!(:has_many)
      
      @database.stub!(:request_class).and_return(@request_class)
      @database.stub!(:source_class).and_return(@source_class)
    end

    it "should register the constant for the line type AR class" do
      @database.send(:create_activerecord_class, @line_definition)
      @database.orm_module.const_defined?('TestLine').should be_true
    end

    it "should create a class that inherits from ActiveRecord::Base and the base class of the ORM module" do
      @database.send(:create_activerecord_class, @line_definition)
      @database.orm_module.const_get('TestLine').ancestors.should include(ActiveRecord::Base, @database.orm_module::Base)
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
        @database.send(:create_activerecord_class, @line_definition)
      end
      
      it "should create a has_many relation on the Request class" do
        @source_class.should_receive(:has_many).with(:test_lines)
        @database.send(:create_activerecord_class, @line_definition)
      end      

      it "should create a belongs_to relation to the Request class" do
        @orm_class.should_receive(:belongs_to).with(:request)
        @database.send(:create_activerecord_class, @line_definition)
      end
      
      it "should create a belongs_to relation to the Source class" do
        @orm_class.should_receive(:belongs_to).with(:source)
        @database.send(:create_activerecord_class, @line_definition)
      end      

      it "should serialize the :evaluate field into the database" do
        @orm_class.should_receive(:serialize).with(:evaluated, Hash)
        @database.send(:create_activerecord_class, @line_definition)
      end
    end
  end
  
  # The create_database_table method should create a database table according to the line definition,
  # so that parsed lines can be stored in it later on.
  describe '#create_database_table' do

    before(:all) do
      @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                            :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                              { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})

      @database = RequestLogAnalyzer::Database.new(testing_format, nil)
    end
    
    before(:each) do
      @connection = mock_connection
      @database.stub!(:connection).and_return(@connection)
    end  

    it "should create a table based on the line type name" do
      @connection.should_receive(:create_table).with(:test_lines)
      @database.send(:create_database_table, @line_definition)
    end

    it "should not create a table based on the line type name if it already exists" do
      @connection.stub!(:table_exists?).with(:test_lines).and_return(true)
      @connection.should_not_receive(:create_table).with(:test_lines)
      @database.send(:create_database_table, @line_definition)
    end


    it "should create an index on the request_id field" do
      @connection.should_receive(:add_index).with(:test_lines, [:request_id])
      @database.send(:create_database_table, @line_definition)
    end

    it "should create a request_id field to link the requests together" do
      @connection.table_creator.should_receive(:column).with(:request_id, :integer)
      @database.send(:create_database_table, @line_definition)
    end

    it "should create a lineno field to save the location of the line in the original file" do
      @connection.table_creator.should_receive(:column).with(:lineno, :integer)
      @database.send(:create_database_table, @line_definition)
    end

    it "should create a field of the correct type for every defined field" do
      @connection.table_creator.should_receive(:column).with(:what, :string)
      @connection.table_creator.should_receive(:column).with(:tries, :integer)
      # :hash capture type should map on a :text field type
      @connection.table_creator.should_receive(:column).with(:evaluated, :text) 
      @database.send(:create_database_table, @line_definition)      
    end

    it "should create a field of the correct type for every provided field" do
      # :duration capture type should map on a :double field type
      @connection.table_creator.should_receive(:column).with(:evaluated_field, :double) 
      @database.send(:create_database_table, @line_definition)   
    end
  end  
end
