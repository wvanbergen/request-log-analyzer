require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Postgresql do

  subject { RequestLogAnalyzer::FileFormat.load(:Postgresql) }
  let(:log_parser)  { RequestLogAnalyzer::Source::LogParser.new(subject) }
  
  it { should be_well_formed }

  describe '#parse_line' do
    it "should parse a :query line correctly" do
      line = '2010-10-10 13:52:07 GMT [38747]: [33-1] LOG:  00000: duration: 0.710 ms  statement: SELECT * FROM "delayed_jobs"'
      subject.should parse_line(line).as(:query).and_capture(:timestamp => 20101010135207, :query_fragment => 'SELECT * FROM "delayed_jobs"')
    end
    
    it "should parse a :query_fragment line correctly" do
      line = '    ("failed_at", "locked_by", "created_at", "handler", "updated_at", "priority", "run_at", "attempts", "locked_at",'
      subject.should parse_line(line).as(:query_fragment).and_capture(:query_fragment => '("failed_at", "locked_by", "created_at", "handler", "updated_at", "priority", "run_at", "attempts", "locked_at",')
    end

    it "should parse a :query line correctly" do
      line = '2010-10-10 13:52:07 GMT [38747]: [33-1] LOG:  00000: duration: 0.710 ms  statement: SELECT * FROM "delayed_jobs"'
      subject.should parse_line(line).as(:query).and_capture(:query_time => 0.710)
    end
  end

  # describe '#parse_io' do
  #   it "should parse a multiline query entry correctly" do
  #     fixture = <<-EOS
  #       2010-10-10 15:00:02 GMT [38747]: [1669-1] LOG:  00000: duration: 0.195 ms  statement: INSERT INTO "delayed_jobs" ("failed_at", "locked_by", "created_at", "handler", "updated_at", "priority", "run_at", "attempts", "locked_at", "last_error") VALUES(NULL, NULL, '2010-10-10 15:00:02.159884', E'--- !ruby/object:RuntheChooChootrain {}
  #         ', '2010-10-10 15:00:02.159884', 0, '2010-10-10 16:00:00.000000', 0, NULL, NULL) RETURNING "id"
  #       2010-10-10 15:00:02 GMT [38747]: [1670-1] LOCATION:  exec_simple_query, postgres.c:1081
  #     EOS
  # 
  #     log_parser.should_not_receive(:warn)
  #     log_parser.parse_string(fixture) do |request|
  #       request[:query].should == 'INSERT INTO delayed_jobs (failed_at, locked_by, created_at, handler, updated_at, priority, run_at, attempts, locked_at, last_error) VALUES(NULL, NULL, :string, E:string, :string, :int, :string, :int, NULL, NULL) RETURNING id'
  #     end
  #   end
  # end
end
