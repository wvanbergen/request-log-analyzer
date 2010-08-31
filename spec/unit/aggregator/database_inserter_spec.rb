require 'spec_helper'

describe RequestLogAnalyzer::Aggregator::DatabaseInserter do

  before(:all) do
    @log_parser = RequestLogAnalyzer::Source::LogParser.new(testing_format)
  end

  # The prepare method is called before the parsing starts. It should establish a connection
  # to a database that is suitable for inserting requests later on.
  describe '#prepare' do

    before(:each) do
      @database = mock_database(:create_database_schema!, :drop_database_schema!, :file_format=)
      @database_inserter = RequestLogAnalyzer::Aggregator::DatabaseInserter.new(@log_parser)
      RequestLogAnalyzer::Database.stub!(:new).and_return(@database)
    end

    it 'should establish the database connection' do
      RequestLogAnalyzer::Database.should_receive(:new).and_return(@database)
      @database_inserter.prepare
    end

    it "should set the file_format" do
      @database.should_receive(:file_format=).with(testing_format)
      @database_inserter.prepare
    end

    it 'should create the database schema during preparation' do
      @database.should_receive(:create_database_schema!)
      @database_inserter.prepare
    end

    it 'should not drop the database schema during preparation if not requested' do
      @database.should_not_receive(:drop_database_schema!)
      @database_inserter.prepare
    end

    it 'should drop the database schema during preparation if requested' do
      @database_inserter.options[:reset_database] = true
      @database.should_receive(:drop_database_schema!)
      @database_inserter.prepare
    end
  end

  test_databases.each do |name, connection|

    context "using a #{name} database" do

      before(:each) do
        @database_inserter = RequestLogAnalyzer::Aggregator::DatabaseInserter.new(@log_parser, :database => connection, :reset_database => true)
        @database_inserter.prepare

        @incomplete_request = testing_format.request( {:line_type => :first, :request_no => 564})
        @completed_request  = testing_format.request( {:line_type => :first, :request_no => 564},
                              {:line_type => :test, :test_capture => "awesome"},
                              {:line_type => :test, :test_capture => "indeed"},
                              {:line_type => :eval, :evaluated => { :greating => 'howdy'}, :greating => 'howdy' },
                              {:line_type => :last, :request_no   => 564})
      end

      after(:each) do
        @database_inserter.database.send :remove_orm_classes!
      end

      it "should insert a record in the request table" do
        lambda {
          @database_inserter.aggregate(@incomplete_request)
        }.should change(RequestLogAnalyzer::Database::Request, :count).from(0).to(1)
      end

      it "should insert a record in the first_lines table" do
        lambda {
          @database_inserter.aggregate(@incomplete_request)
        }.should change(@database_inserter.database.get_class(:first), :count).from(0).to(1)
      end

      it "should insert records in all relevant line tables" do
        @database_inserter.aggregate(@completed_request)
        request = RequestLogAnalyzer::Database::Request.first
        request.should have(2).test_lines
        request.should have(1).first_lines
        request.should have(1).eval_lines
        request.should have(1).last_lines
      end

      it "should log a warning in the warnings table" do
        RequestLogAnalyzer::Database::Warning.should_receive(:create!).with(hash_including(:warning_type => 'test_warning'))
        @database_inserter.warning(:test_warning, "Testing the warning system", 12)
      end
    end
  end
end