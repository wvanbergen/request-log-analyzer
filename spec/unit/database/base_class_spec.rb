require 'spec_helper'
require 'request_log_analyzer/database'

describe RequestLogAnalyzer::Database::Base do

  describe '.subclass_from_line_definition' do
    before(:all) do
      @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                          :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                            { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})
    end

    before(:each) do
      @orm_class = mock('Line ActiveRecord::Base class')
      @orm_class.stub!("table_name=")
      @orm_class.stub!(:belongs_to)
      @orm_class.stub!(:serialize)
      @orm_class.stub!(:line_definition=)

      RequestLogAnalyzer::Database::Request.stub!(:has_many)
      RequestLogAnalyzer::Database::Source.stub!(:has_many)

      @database = mock_database
      RequestLogAnalyzer::Database::Base.stub!(:database).and_return(@database)
    end

    it "should create a new subclass using the Base class as parent" do
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should store the LineDefinition" do
      @orm_class.should_receive(:line_definition=).with(@line_definition)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should set the table name for the subclass" do
      @orm_class.should_receive("table_name=").with('test_lines')
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should set the :belongs_to relationship with the Request class" do
      @orm_class.should_receive(:belongs_to).with(:request, {:class_name=>"RequestLogAnalyzer::Database::Request"})
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should set a :has_many relationship in the request class" do
      RequestLogAnalyzer::Database::Request.should_receive(:has_many).with(:test_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should set a :has_many relationship in the source class" do
      RequestLogAnalyzer::Database::Source.should_receive(:has_many).with(:test_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should set the :belongs_to relationship with the Source class" do
      @orm_class.should_receive(:belongs_to).with(:source, {:class_name=>"RequestLogAnalyzer::Database::Source"})
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

    it "should serialize a complex field" do
      @orm_class.should_receive(:serialize).with(:evaluated, Hash)
      RequestLogAnalyzer::Database::Base.subclass_from_line_definition(@line_definition, @orm_class)
    end

  end

  describe '.subclass_from_table' do
    before(:each) do

      RequestLogAnalyzer::Database::Request.stub!(:has_many)
      RequestLogAnalyzer::Database::Source.stub!(:has_many)

      @database = mock_database
      @database.connection.stub!(:table_exists?).and_return(true)
      RequestLogAnalyzer::Database::Base.stub!(:database).and_return(@database)

      @klass = mock('ActiveRecord ORM class')
      @klass.stub!(:column_names).and_return(['id', 'request_id', 'source_id', 'lineno', 'duration'])
      @klass.stub!("table_name=")
      @klass.stub!(:belongs_to)
    end

    it "should set the table name" do
      @klass.should_receive("table_name=").with('completed_lines')
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines', @klass)
    end

    it "should create the :belongs_to relation to the request class" do
      @klass.should_receive(:belongs_to).with(:request, {:class_name=>"RequestLogAnalyzer::Database::Request"})
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines', @klass)
    end

    it "should create the :has_many relation in the request class" do
      RequestLogAnalyzer::Database::Request.should_receive(:has_many).with(:completed_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines', @klass)
    end

    it "should create the :belongs_to relation to the source class" do
      @klass.should_receive(:belongs_to).with(:source, {:class_name=>"RequestLogAnalyzer::Database::Source"})
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines', @klass)
    end

    it "should create the :has_many relation in the request class" do
      RequestLogAnalyzer::Database::Source.should_receive(:has_many).with(:completed_lines)
      RequestLogAnalyzer::Database::Base.subclass_from_table('completed_lines', @klass)
    end

  end

  describe '#create_table' do

    before(:all) do
      @line_definition = RequestLogAnalyzer::LineDefinition.new(:test, { :regexp   => /Testing (\w+), tries\: (\d+)/,
                            :captures => [{ :name => :what, :type => :string }, { :name => :tries, :type => :integer },
                              { :name => :evaluated, :type => :hash, :provides => {:evaluated_field => :duration} }]})
    end

    before(:each) do
      @database = RequestLogAnalyzer::Database.new
      @database.stub!(:connection).and_return(mock_connection)
      @klass = @database.load_activerecord_class(@line_definition)
      @klass.stub!(:table_exists?).and_return(false)
    end

    after(:each) do
      @klass.drop_table!
      @database.remove_orm_classes!
    end

    it "should call create_table with the correct table name" do
      @database.connection.should_receive(:create_table).with(:test_lines)
      @klass.create_table!
    end

    it "should not create a table based on the line type name if it already exists" do
      @klass.stub!(:table_exists?).and_return(true)
      @database.connection.should_not_receive(:create_table).with(:test_lines)
      @klass.create_table!
    end

    it "should create an index on the request_id field" do
      @database.connection.should_receive(:add_index).with(:test_lines, [:request_id])
      @klass.create_table!
    end

    it "should create an index on the source_id field" do
      @database.connection.should_receive(:add_index).with(:test_lines, [:source_id])
      @klass.create_table!
    end

    it "should create a request_id field to link the requests together" do
      @database.connection.table_creator.should_receive(:column).with(:request_id, :integer)
      @klass.create_table!
    end

    it "should create a lineno field to save the location of the line in the original file" do
      @database.connection.table_creator.should_receive(:column).with(:lineno, :integer)
      @klass.create_table!
    end

    it "should create a field of the correct type for every defined capture field" do
      @database.connection.table_creator.should_receive(:column).with(:what, :string)
      @database.connection.table_creator.should_receive(:column).with(:tries, :integer)
      @database.connection.table_creator.should_receive(:column).with(:evaluated, :text)
      @klass.create_table!
    end

    it "should create a field of the correct type for every provided field" do
      @database.connection.table_creator.should_receive(:column).with(:evaluated_field, :double)
      @klass.create_table!
    end
  end
end

