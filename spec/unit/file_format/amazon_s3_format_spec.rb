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

  it "should parse a COPY request correctly" do
    line = '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a testbucket [03/Mar/2010:23:04:59 +0000] 174.119.31.76 09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a ACCC34B843C87BC9 REST.COPY.OBJECT files/image.png "PUT /files/image.png HTTP/1.1" 200 - 234 65957 365 319 "-" "" -'
    @file_format.should parse_line(line).as(:access).and_capture(
        :bucket_owner    => '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a', 
        :bucket          => 'testbucket', 
        :timestamp       => 20100303230459, 
        :remote_ip       => '174.119.31.76', 
        :requester       => '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a',
        :key             => 'files/image.png', 
        :operation       => 'REST.COPY.OBJECT', 
        :total_time      => 0.365, 
        :turnaround_time => 0.319, 
        :bytes_sent      => 234, 
        :object_size     => 65957, 
        :referer         => nil,
        :user_agent      => '')
  end

end