require 'spec_helper'
require 'request_log_analyzer/database'

describe RequestLogAnalyzer::Database do

  describe '#load_database_schema!' do

    context 'for a Rails request database' do
      before(:each) do
        @database = RequestLogAnalyzer::Database.new(log_fixture(:rails, :db))
        @database.load_database_schema!
      end

      after(:each) { @database.remove_orm_classes! }

      # FileFormat-agnostic classes
      default_orm_class_names.each do |const|
        it "should create the default #{const} constant" do
          RequestLogAnalyzer::Database.const_defined?(const).should be_true
        end

        it "should create the default #{const} class inheriting from ActiveRecord::Base and RequestLogAnalyzer::Database::Base" do
          RequestLogAnalyzer::Database.const_get(const).ancestors.should include(ActiveRecord::Base, RequestLogAnalyzer::Database::Base)
        end
      end

      # Some Fileformat-specific classes
      ['CompletedLine', 'ProcessingLine'].each do |const|
        it "should create the #{const} constant" do
          Object.const_defined?(const).should be_true
        end

        it "should create the #{const} class inheriting from ActiveRecord::Base and RequestLogAnalyzer::Database::Base" do
          Object.const_get(const).ancestors.should include(ActiveRecord::Base, RequestLogAnalyzer::Database::Base)
        end

        it "should create a :belongs_to relation from the #{const} class to Request and Source" do
          Object.const_get(const).send(:reflections).should include(:request, :source)
        end

        it "should create a :has_many relation from the Request and Source class to the #{const} class" do
          RequestLogAnalyzer::Database::Request.send(:reflections).should include(const.underscore.pluralize.to_sym)
          RequestLogAnalyzer::Database::Source.send(:reflections).should include(const.underscore.pluralize.to_sym)
        end
      end
    end
  end

  describe '#create_database_schema!' do

    before(:each) do
      @database = RequestLogAnalyzer::Database.new
      @database.file_format = testing_format
      @database.stub!(:connection).and_return(mock_connection)

      # Stub the expected method calls for the preparation, these will be tested separately
      @mock_class = Class.new(RequestLogAnalyzer::Database::Base)
      @mock_class.stub!(:create_table!)
    end

    after(:each) { @database.remove_orm_classes! }

    default_orm_class_names.each do |klass|

      it "should create a table for the default #{klass} class" do
        @database.connection.should_receive(:create_table).with(klass.underscore.pluralize.to_sym)
        @database.send :create_database_schema!
      end

      it "should create a #{klass} class inheriting from ActiveRecord and the base class of the ORM module" do
        @database.send :create_database_schema!
        RequestLogAnalyzer::Database.const_get(klass).ancestors.should include(ActiveRecord::Base, RequestLogAnalyzer::Database::Base)
      end
    end

    testing_format.line_definitions.each do |name, definition|

      it "should create the #{(name.to_s + '_line').camelize} class for #{name.inspect} lines" do
        @database.send :create_database_schema!
        Object.const_defined?("#{name}_line".camelize).should be_true
      end

      it "should create the #{name.to_s + '_lines'} table for the parsed #{name.inspect} lines" do
        @database.connection.should_receive(:create_table).with("#{name}_lines".to_sym)
        @database.send :create_database_schema!
      end
    end
  end

  describe '#load_activerecord_class' do

    before(:each) do
      @database = RequestLogAnalyzer::Database.new
      @connection = mock_connection
      @database.stub!(:connection).and_return(@connection)

      # Mock the has_many method of the defaukt ORM classes
      RequestLogAnalyzer::Database::Request.stub!(:has_many)
      RequestLogAnalyzer::Database::Source.stub!(:has_many)

      @mock_class = Class.new(RequestLogAnalyzer::Database::Base)

      RequestLogAnalyzer::Database::Base.stub!(:subclass_from_table).and_return(@mock_class)
      RequestLogAnalyzer::Database::Base.stub!(:subclass_from_line_definition).and_return(@mock_class)
    end

    after(:each) { @database.remove_orm_classes! }

    it "should call :subclass_from_table when a table name is given as string" do
      RequestLogAnalyzer::Database::Base.should_receive(:subclass_from_table).and_return(@mock_class)
      @database.load_activerecord_class('test_lines')
    end

    it "should call :subclass_from_table when a table name is given as symbol" do
      RequestLogAnalyzer::Database::Base.should_receive(:subclass_from_table).and_return(@mock_class)
      @database.load_activerecord_class(:test_lines)
    end

    it "should call :subclass_from_table when a LineDefinition is given" do
      RequestLogAnalyzer::Database::Base.should_receive(:subclass_from_line_definition).and_return(@mock_class)
      @database.load_activerecord_class(RequestLogAnalyzer::LineDefinition.new(:test))
    end

    it "should define the class in the ORM module" do
      @database.load_activerecord_class(:test_lines)
      Object.const_defined?('TestLine').should be_true
    end

    it "should add the class to the line_classes array of the database" do
      @database.load_activerecord_class(:test_lines)
      @database.line_classes.should include(TestLine)
    end
  end
end
