require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rack do
  
  subject { RequestLogAnalyzer::FileFormat.load(:rack)} 
  let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
  
  it { should be_well_formed }
  it { should have_line_definition(:access).capturing(:remote_host, :timestamp, :http_method, :path, 
          :http_version, :http_status, :bytes_sent, :duration) }

  let(:sample) { '127.0.0.1 - - [23/Nov/2009 21:47:47] "GET /css/stylesheet.css HTTP/1.1" 200 3782 0.0024' }
  let(:irrelevant) { '== Sinatra/0.9.4 has taken the stage on 4567 for development with backup from Mongrel' }

  describe '#parse_line' do
    
    it { should parse_line(sample, 'a sample access line').and_capture(
              :remote_host    => '127.0.0.1',
              :timestamp      => 20091123214747,
              :http_method    => 'GET',
              :path           => '/css/stylesheet.css',
              :http_version   => '1.1',
              :http_status    => 200,
              :bytes_sent     => 3782,
              :duration       => 0.0024)
    }
    
    it { should_not parse_line(irrelevant, 'an irrelevant line') }
    it { should_not parse_line('nonsense', 'a nonsense line') }  
  end

  describe '#parse_io' do
    let(:snippet) { irrelevant << "\n" << sample << "\n" << sample << "\n" }
    
    it "shouldparse a snippet without warnings" do
      request_counter.should_receive(:hit!).twice
      log_parser.should_not_receive(:warn)
      log_parser.parse_string(snippet) { request_counter.hit! }
    end
  end
end
