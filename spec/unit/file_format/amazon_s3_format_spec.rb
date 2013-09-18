require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::AmazonS3 do

  subject { RequestLogAnalyzer::FileFormat.load(:amazon_s3) }

  it { should be_well_formed }
  it { should have_line_definition(:access).capturing(:bucket_owner, :bucket, :timestamp, :remote_ip, :requester,
        :key, :operation, :total_time, :turnaround_time, :bytes_sent, :object_size, :referer, :user_agent) }

  it { should have(7).report_trackers }

  let(:sample_get)  { '2f88111968424e6306bf4d292c0188ccb94ff9374ea2836b50a1a79f7cd656e1 sample-bucket [06/Oct/2006:01:42:14 +0000] 207.171.172.6 65a011a29cdf8ec533ec3d1ccaae921c C980091AD89C936A REST.GET.OBJECT object.png "GET /sample-bucket/object.png HTTP/1.1" 200 - 1243 1243 988 987 "-" "aranhabot"' }
  let(:sample_copy) { '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a testbucket [03/Mar/2010:23:04:59 +0000] 174.119.31.76 09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a ACCC34B843C87BC9 REST.COPY.OBJECT files/image.png "PUT /files/image.png HTTP/1.1" 200 - 234 65957 365 319 "-" "" -' }
  let(:sample_2013) { 'ccc30d58fff2fad852150fa6f9e7bd14b5f6d2ea83f2deec4a610bf0f0a8f7ac testbucket [17/Sep/2013:15:53:53 +0000] 87.193.165.87 - A9774F82F053FACE REST.GET.OBJECT somefile.txt "GET /testbucket/somefile.txt HTTP/1.1" 304 - - 1071 9 - "https://s3-console-us-standard.console.aws.amazon.com/GetResource/Console.html?region=eu-west-1&pageLoadStartTime=1379427139127&locale=en_US" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36" -' }

  describe '#parse_line' do
    it {
      should parse_line(sample_get, 'a GET line').and_capture(
        :bucket_owner    => '2f88111968424e6306bf4d292c0188ccb94ff9374ea2836b50a1a79f7cd656e1',
        :bucket          => 'sample-bucket',
        :timestamp       => 20061006014214,
        :remote_ip       => '207.171.172.6',
        :key             => 'object.png',
        :operation       => 'REST.GET.OBJECT',
        :requester       => '65a011a29cdf8ec533ec3d1ccaae921c',
        :request_id      => 'C980091AD89C936A',
        :request_uri     => 'GET /sample-bucket/object.png HTTP/1.1',
        :error_code      => nil,
        :http_status     => 200,
        :total_time      => 0.988,
        :turnaround_time => 0.987,
        :bytes_sent      => 1243,
        :object_size     => 1243,
        :user_agent      => 'aranhabot',
        :referer         => nil)
    }

    it { should parse_line(sample_2013, '2013 sample').and_capture(
        :bucket_owner    => 'ccc30d58fff2fad852150fa6f9e7bd14b5f6d2ea83f2deec4a610bf0f0a8f7ac',
        :bucket          => 'testbucket',
        :timestamp       => 20130917155353,
        :remote_ip       => '87.193.165.87',
        :requester       => '-',
        :request_id      => 'A9774F82F053FACE',
        :operation       => 'REST.GET.OBJECT',
        :key             => 'somefile.txt',
        :request_uri     => "GET /testbucket/somefile.txt HTTP/1.1",
        :http_status     => 304,
        :error_code      => nil,
        :bytes_sent      => 0,
        :object_size     => 1071,
        :total_time      => 0.009,
        :turnaround_time => 0,
        :referer         => "https://s3-console-us-standard.console.aws.amazon.com/GetResource/Console.html?region=eu-west-1&pageLoadStartTime=1379427139127&locale=en_US",
        :user_agent      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.65 Safari/537.36")
    }

    it {should parse_line(sample_copy, 'a COPY line').and_capture(
        :bucket_owner    => '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a',
        :bucket          => 'testbucket',
        :timestamp       => 20100303230459,
        :remote_ip       => '174.119.31.76',
        :key             => 'files/image.png',
        :operation       => 'REST.COPY.OBJECT',
        :requester       => '09216466b5571a8db0bf5abca72041fd3fc163e5eb83c51159735353ac6a2b9a',
        :request_id      => 'ACCC34B843C87BC9',
        :request_uri     => 'PUT /files/image.png HTTP/1.1',
        :error_code      => nil,
        :http_status     => 200,
        :total_time      => 0.365,
        :turnaround_time => 0.319,
        :bytes_sent      => 234,
        :object_size     => 65957,
        :user_agent      => '',
        :referer         => nil)
    }

    it { should_not parse_line('nonsense', 'a nonsense line') }
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
    let(:snippet) { log_snippet(sample_get, sample_copy, 'nonsense line') }

    it "should parse requests correctly and not generate warnings" do
      log_parser.should_receive(:handle_request).twice
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(snippet)
    end
  end
end