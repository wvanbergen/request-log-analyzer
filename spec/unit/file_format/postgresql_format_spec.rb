require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Postgresql do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:Postgresql).should be_valid
  end

  describe '#parse_line' do
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:Postgresql)
    end

    it "should parse a :query line correctly" do
      line = '2004-05-07 11:58:36 LOG:  query: SELECT plugin_id, plugin_name FROM plugins'
      @file_format.should parse_line(line).as(:query).and_capture(:timestamp => 20040507115836, :query_fragment => 'SELECT plugin_id, plugin_name FROM plugins')
    end
    
    it "should parse a :query_fragment line correctly" do
      line = '    groups.type_id,users.user_name,users.realname,'
      @file_format.should parse_line(line).as(:query_fragment).and_capture(:query_fragment => "groups.type_id,users.user_name,users.realname,")
    end

    it "should parse a :duration line correctly" do
      line = '2004-05-07 11:58:36 LOG:  duration: 0.002612 sec'
      @file_format.should parse_line(line).as(:duration).and_capture(:query_time => 0.002612)
    end    
  end

  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:postgresql))
    end

    it "should parse a multiline query entry correctly" do
      fixture = <<EOS
2004-05-07 11:58:22 LOG:  query: SELECT groups.group_name,groups.unix_group_name,
		groups.type_id,users.user_name,users.realname,
		news_bytes.forum_id,news_bytes.summary,news_bytes.post_date,news_bytes.details 
		FROM users,news_bytes,groups 
		WHERE news_bytes.group_id='98' AND news_bytes.is_approved <> '4' 
		AND users.user_id=news_bytes.submitted_by 
		AND news_bytes.group_id=groups.group_id 
		ORDER BY post_date DESC LIMIT 10 OFFSET 0
2004-05-07 11:58:22 LOG:  duration: 0.002680 sec
EOS
      @log_parser.parse_io(StringIO.new(fixture)) do |request|
        request.should be_kind_of(RequestLogAnalyzer::FileFormat::Postgresql::Request)
        request[:query].should == "SELECT groups.group_name,groups.unix_group_name, groups.type_id,users.user_name,users.realname, news_bytes.forum_id,news_bytes.summary,news_bytes.post_date,news_bytes.details FROM users,news_bytes,groups WHERE news_bytes.group_id=:string AND news_bytes.is_approved <> :string AND users.user_id=news_bytes.submitted_by AND news_bytes.group_id=groups.group_id ORDER BY post_date DESC LIMIT :int OFFSET :int"
      end
    end

    it "should parse a dualline query entry correctly" do
      fixture = <<EOS
      2004-05-07 11:58:36 LOG:  query: SELECT type, count FROM project_sums_agg WHERE group_id=59
      2004-05-07 11:58:36 LOG:  duration: 0.001197 sec
EOS
      @log_parser.parse_io(StringIO.new(fixture)) do |request|
        request.should be_kind_of(RequestLogAnalyzer::FileFormat::Postgresql::Request)
        request[:query].should == "SELECT type, count FROM project_sums_agg WHERE group_id=:int"
      end
    end
  end
end

