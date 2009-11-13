require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Mysql do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:mysql).should be_valid
  end

  describe '#parse_line' do
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:mysql)
    end
    
    # SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`; 
    
    it "should parse a :time line correctly" do
      line = '# Time: 091112 8:13:56'
      @file_format.should parse_line(line).as(:time).and_capture(:timestamp => 20091112081356)
    end

    it "should parse a :user_host line correctly with IP present" do
      line = '# User@Host: admin[admin] @ db1 [10.0.0.1]'
      @file_format.should parse_line(line).as(:user_host).and_capture(:user => "admin", :host => 'db1', :ip => '10.0.0.1')
    end

    it "should parse a :user_host line correctly with IP absent" do
      line = '# User@Host: root[root] @ localhost []'
      @file_format.should parse_line(line).as(:user_host).and_capture(:user => "root", :host => 'localhost', :ip => "")
    end

    it "should parse a :query_statistics line" do
      line = '# Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307'
      @file_format.should parse_line(line).as(:query_statistics).and_capture(:query_time => 10.0,
          :lock_time => 0.0, :rows_sent => 1191307, :rows_examined => 1191307)
    end

    it "should parse a :query_statistics line with floating point durations" do
      line = '# Query_time: 10.00000  Lock_time: 0.00000  Rows_sent: 1191307  Rows_examined: 1191307'
      @file_format.should parse_line(line).as(:query_statistics).and_capture(:query_time => 10.0,
          :lock_time => 0.0, :rows_sent => 1191307, :rows_examined => 1191307)
    end
    
    it "should parse a :query_part line" do
      line = '                               AND clients.index > 0'
      @file_format.should parse_line(line).as(:query_part).and_capture(:query_fragment => line)
    end
    
    it "should parse a final :query line" do
      line = 'SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`; '
      @file_format.should parse_line(line).as(:query).and_capture(:query =>
        'SELECT /*!:int SQL_NO_CACHE */ * FROM events')
    end

  end

  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:mysql))
    end

    it "should parse a single line query entry correctly" do
      fixture = <<EOS
# Time: 091112 18:13:56
# User@Host: admin[admin] @ db1 [10.0.0.1]
# Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
SELECT /*!40001 SQL_NO_CACHE */ * FROM `events`;
EOS
      @log_parser.parse_io(StringIO.new(fixture)) do |request|
        request.should be_kind_of(RequestLogAnalyzer::FileFormat::Mysql::Request)
        request[:query].should == 'SELECT /*!:int SQL_NO_CACHE */ * FROM events'
      end
    end

    it "should parse a multiline query entry correctly" do
      fixture = <<EOS
# Time: 091112 18:13:56
# User@Host: admin[admin] @ db1 [10.0.0.1]
# Query_time: 10  Lock_time: 0  Rows_sent: 1191307  Rows_examined: 1191307
SELECT * FROM `clients` WHERE (1=1 
                              AND clients.valid_from < '2009-12-05' AND (clients.valid_to IS NULL or clients.valid_to > '2009-11-20')
                               AND clients.index > 0
                              ) AND (clients.deleted_at IS NULL);
EOS
      @log_parser.parse_io(StringIO.new(fixture)) do |request|
        request.should be_kind_of(RequestLogAnalyzer::FileFormat::Mysql::Request)
        request[:query].should == "SELECT * FROM clients WHERE (:int=:int AND clients.valid_from < :date AND (clients.valid_to IS NULL or clients.valid_to > :date) AND clients.index > :int ) AND (clients.deleted_at IS NULL)"
      end
    end

    it "should find 26 completed sloq query entries" do
      @log_parser.should_receive(:handle_request).exactly(26).times
      @log_parser.parse_file(log_fixture(:mysql_slow_query))
    end
  end
end
