require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Mysql do

  subject { RequestLogAnalyzer::FileFormat.load(:mysql) }
  
  it { should be_well_formed }
  it { should have_line_definition(:time).capturing(:timestamp) }
  it { should have_line_definition(:user_host).capturing(:user, :host, :ip) }
  it { should have_line_definition(:query_statistics).capturing(:query_time, :lock_time, :rows_sent, :rows_examined) }
  it { should have_line_definition(:use_database).capturing(:database) }
  it { should have_line_definition(:query_part).capturing(:query_fragment) }
  it { should have_line_definition(:query).capturing(:query) }
  it { should have(7).report_trackers }
  
  describe '#parse_line' do
    
    let(:time_sample)                   { '# Time: 091112  8:13:56' }
    let(:user_host_sample)              { '# User@Host: admin[admin] @ db1 [10.0.0.1]' }
    let(:user_host_wo_host_sample)      { '# User@Host: admin[admin] @  [10.0.0.1]' }
    let(:user_host_wo_ip_sample)        { '# User@Host: root[root] @ localhost []' }
    let(:float_query_statistics_sample) { '# Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307' }
    let(:int_query_statistics_sample)   { '# Query_time: 10.00000  Lock_time: 0.00000  Rows_sent: 1191307  Rows_examined: 1191307' }
    let(:partial_query_sample)          { 'AND clients.index > 0' }
    let(:full_query_sample)             { 'SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`; ' }
    let(:use_db_sample)                 { 'use db;' }
    let(:set_timestamp_sample)          { 'SET timestamp=1250651725;' }
    let(:set_insertid_sample)           { 'SET insert_id=1250651725;' }
    let(:set_timestamp_insertid_sample) { 'SET timestamp=1250651725, insert_id=45674;' }

    it { should parse_line(time_sample).as(:time).and_capture(:timestamp => 20091112081356) }
    it { should parse_line(user_host_sample).as(:user_host).and_capture(:user => "admin", :host => 'db1', :ip => '10.0.0.1') }
    it { should parse_line(user_host_wo_host_sample, 'without host').as(:user_host).and_capture(:user => "admin", :host => '', :ip => '10.0.0.1') }
    it { should parse_line(user_host_wo_ip_sample, 'without IP').as(:user_host).and_capture(:user => "root", :host => 'localhost', :ip => "") }
    it { should parse_line(float_query_statistics_sample, 'using floats').as(:query_statistics).and_capture(:query_time => 10.0, :lock_time => 0.0, :rows_sent => 1191307, :rows_examined => 1191307) }
    it { should parse_line(int_query_statistics_sample, 'using integers').as(:query_statistics).and_capture(:query_time => 10.0, :lock_time => 0.0, :rows_sent => 1191307, :rows_examined => 1191307) }
    it { should parse_line(partial_query_sample).as(:query_part).and_capture(:query_fragment => 'AND clients.index > 0') }
    it { should parse_line(full_query_sample).as(:query).and_capture(:query => 'SELECT /*!:int SQL_NO_CACHE */ * FROM events') }
    it { should parse_line(use_db_sample).as(:use_database).and_capture(:database => 'db') }

    it { should_not parse_line(set_timestamp_sample) }
    it { should_not parse_line(set_insertid_sample) }
    it { should_not parse_line(set_timestamp_insertid_sample) }
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }

    it "should parse a single line query entry correctly" do
      fixture = <<-EOS
        # Time: 091112 18:13:56
        # User@Host: admin[admin] @ db1 [10.0.0.1]
        # Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
        SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`;
      EOS
      
      log_parser.parse_string(fixture) do |request|
        request[:query].should == 'SELECT /*!:int SQL_NO_CACHE */ * FROM events'
      end
    end

    it "should parse a multiline query entry correctly" do
      fixture = <<-EOS
        # Time: 091112 18:13:56
        # User@Host: admin[admin] @ db1 [10.0.0.1]
        # Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
        SELECT * FROM `clients` WHERE (1=1 
                                      AND clients.valid_from < '2009-12-05' AND (clients.valid_to IS NULL or clients.valid_to > '2009-11-20')
                                       AND clients.index > 0
                                      ) AND (clients.deleted_at IS NULL);
      EOS
      
      log_parser.parse_string(fixture) do |request|
        request[:query].should == "SELECT * FROM clients WHERE (:int=:int AND clients.valid_from < :date AND (clients.valid_to IS NULL or clients.valid_to > :date) AND clients.index > :int ) AND (clients.deleted_at IS NULL)"
      end
    end

    it "should parse a request without timestamp correctly, without warnings" do
        fixture = <<-EOS
        # User@Host: admin[admin] @ db1 [10.0.0.1]
        # Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
        SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`;
      EOS
      
      log_parser.should_receive(:handle_request).once
      log_parser.should_not_receive(:warn)
      log_parser.parse_string(fixture)
    end

    it "should parse a query with context information correctly" do
      fixture = <<-EOS
        # Time: 091112 18:13:56
        # User@Host: admin[admin] @ db1 [10.0.0.1]
        # Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
        use database_name;
        SET timestamp=4324342342423, insert_id = 224253443;
        SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`;
      EOS

      log_parser.parse_string(fixture) do |request|
        request[:query].should == 'SELECT /*!:int SQL_NO_CACHE */ * FROM events'
      end
    end

    it "should find 26 completed sloq query entries" do
      log_parser.should_not_receive(:warn)
      log_parser.should_receive(:handle_request).exactly(26).times
      log_parser.parse_file(log_fixture(:mysql_slow_query))
    end
  end
end
