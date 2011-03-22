require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::W3c do

  subject { RequestLogAnalyzer::FileFormat.load(:w3c) }

  it { should be_well_formed }
  it { should have_line_definition(:access).capturing(:timestamp, :remote_ip, :username, :local_ip, :port,
            :method, :path, :http_status, :bytes_sent, :bytes_received, :duration, :user_agent, :referer) }

  it { should have(10).report_trackers }
  
  let(:sample1) { '2002-05-24 20:18:01 172.224.24.114 - 206.73.118.24 80 GET /Default.htm - 200 7930 248 31 Mozilla/4.0+(compatible;+MSIE+5.01;+Windows+2000+Server) http://64.224.24.114/' }
  let(:irrelevant) { '#Software: Microsoft Internet Information Services 6.0' }
  
  describe '#parse_line' do
    it { should parse_line(sample1, 'an access line').and_capture(
              :timestamp      => 20020524201801,
              :remote_ip      => "172.224.24.114",
              :username       => nil,
              :local_ip       => "206.73.118.24",
              :port           => 80,
              :method         => 'GET',
              :path           => '/Default.htm',
              :http_status    => 200,
              :bytes_sent     => 7930,
              :bytes_received => 248,
              :duration       => 0.031,
              :user_agent     => 'Mozilla/4.0+(compatible;+MSIE+5.01;+Windows+2000+Server)',
              :referer        => 'http://64.224.24.114/')
    }
    
    it { should_not parse_line(irrelevant, 'an irrelevant line') }
    it { should_not parse_line('nonsense', 'a nonsense line') }
  end
  
  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
    let(:snippet) { log_snippet(irrelevant, sample1, sample1) }
    
    it "should parse a snippet successully without warnings" do
      log_parser.should_receive(:handle_request).twice
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(snippet)
    end
  end
end
