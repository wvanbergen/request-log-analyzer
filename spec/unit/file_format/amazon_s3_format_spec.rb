require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::AmazonS3 do

  before(:each) do
    @file_format = RequestLogAnalyzer::FileFormat.load(:amazon_s3)
    @log_parser  = RequestLogAnalyzer::Source::LogParser.new(@file_format)
    @sample = '2f88111968424e6306bf4d292c0188ccb94ff9374ea2836b50a1a79f7cd656e1 sample-bucket [06/Oct/2006:01:42:14 +0000] 207.171.172.6 65a011a29cdf8ec533ec3d1ccaae921c C980091AD89C936A REST.GET.OBJECT object.png "GET /sample-bucket/object.png HTTP/1.1" 200 - 1243 1243 988 987 "-" "aranhabot"'
  end

  it "should be a valid file format" do
    @file_format.should be_valid
  end

  it "should parse access lines and capture all of its fields" do
    @file_format.should have_line_definition(:access).capturing(:bucket_owner, :bucket, :timestamp, :remote_ip, :requester,
          :key, :operation, :total_time, :turnaround_time, :bytes_sent, :object_size, :referer, :user_agent)
  end

  it "should match the sample line" do
    @file_format.parse_line(@sample).should include(:line_definition, :captures)
  end

  it "should not match a nonsense line" do
    @file_format.parse_line('dsadasdas dsaadsads dsaadsads').should be_nil
  end

  it "should parse and convert the sample fields correctly" do
    @log_parser.parse_io(StringIO.new(@sample)) do |request|
      request[:bucket_owner].should    == '2f88111968424e6306bf4d292c0188ccb94ff9374ea2836b50a1a79f7cd656e1'
      request[:bucket].should          == 'sample-bucket'
      request[:remote_ip].should       == '207.171.172.6'
      request[:key].should             == 'object.png'
      request[:operation].should       == 'REST.GET.OBJECT'
      request[:requester].should       == '65a011a29cdf8ec533ec3d1ccaae921c'
      request[:request_id].should      == 'C980091AD89C936A'
      request[:request_uri].should     == 'GET /sample-bucket/object.png HTTP/1.1'
      request[:error_code].should      == nil
      request[:http_status].should     == 200
      request[:total_time].should      == 0.988
      request[:turnaround_time].should == 0.987
      request[:bytes_sent].should      == 1243
      request[:object_size].should     == 1243
      request[:user_agent].should      == 'aranhabot'
      request[:referer].should         == nil
    end
  end

end