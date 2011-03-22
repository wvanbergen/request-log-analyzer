require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rack do
  
  subject { RequestLogAnalyzer::FileFormat.load(:rack)} 
  let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
  
  it { should be_well_formed }
  it { should have_line_definition(:access).capturing(:remote_host, :user, :remote_logname, 
          :timestamp, :http_method, :path, :http_version, :http_status, :bytes_sent, :duration) }

  it { should have(7).report_trackers }

  let(:sample1) { '127.0.0.1 - - [23/Nov/2009 21:47:47] "GET /css/stylesheet.css HTTP/1.1" 200 3782 0.0024' }
  let(:sample2) { '127.0.0.1 - - [16/Sep/2009 07:40:08] "GET /favicon.ico HTTP/1.1" 500 63183 0.0453' }
  let(:sample3) { '127.0.0.1 - - [01/Oct/2009 07:58:10] "GET / HTTP/1.1" 200 1 0.0045' }
  let(:irrelevant) { '== Sinatra/0.9.4 has taken the stage on 4567 for development with backup from Mongrel' }

  describe '#parse_line' do
    
    it { should parse_line(sample1, 'a sample access line').and_capture(
            :remote_host => '127.0.0.1', :timestamp => 20091123214747, :user => nil,
            :http_status => 200,         :http_method => 'GET',        :http_version => '1.1',
            :duration => 0.0024,         :bytes_sent => 3782,         :remote_logname => nil,
            :path => '/css/stylesheet.css')
    }
    
    it { should parse_line(sample2, 'another sample access line').and_capture(
            :remote_host => '127.0.0.1', :timestamp => 20090916074008, :user => nil,
            :http_status => 500,         :http_method => 'GET',        :http_version => '1.1',
            :duration => 0.0453,         :bytes_sent => 63183,         :remote_logname => nil,
            :path => '/favicon.ico')
    }
    
    it { should parse_line(sample3, 'a third sample access line').and_capture(
            :remote_host => '127.0.0.1', :timestamp => 20091001075810, :user => nil,
            :http_status => 200,         :http_method => 'GET',        :http_version => '1.1',
            :duration => 0.0045,         :bytes_sent => 1,             :remote_logname => nil,
            :path => '/')
    }
    
    it { should_not parse_line(irrelevant, 'an irrelevant line') }
    it { should_not parse_line('nonsense', 'a nonsense line') }  
  end

  describe '#parse_io' do
    let(:snippet) { log_snippet(irrelevant, sample1, sample2, sample3) }
    
    it "shouldparse a snippet without warnings" do
      log_parser.should_receive(:handle_request).exactly(3).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(snippet)
    end
  end
end
