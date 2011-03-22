require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Haproxy do

  subject { RequestLogAnalyzer::FileFormat.load(:haproxy) }

  it { should be_well_formed }
  it { should have_line_definition(:access).capturing(:client_ip, :timestamp, :frontend_name, :backend_name, :server_name, :tq, :tw, :tc, :tr, :tt, :status_code, :bytes_read, :captured_request_cookie, :captured_response_cookie, :termination_event_code, :terminated_session_state, :clientside_persistence_cookie, :serverside_persistence_cookie, :actconn, :feconn, :beconn, :srv_conn, :retries, :srv_queue, :backend_queue, :captured_request_headers, :captured_response_headers, :http_request) }
  it { should have(14).report_trackers }

  let(:sample1) { 'Feb  6 12:14:14 localhost haproxy[14389]: 10.0.1.2:33317 [06/Feb/2009:12:14:14.655] http-in static/srv1 10/0/30/69/109 200 2750 - - ---- 1/1/1/1/0 0/0 {1wt.eu} {} "GET /index.html HTTP/1.1"' }
  let(:sample2) { 'haproxy[18113]: 127.0.0.1:34549 [15/Oct/2003:15:19:06.103] px-http px-http/<NOSRV> -1/-1/-1/-1/+50001 408 +2750 - - cR-- 2/2/2/0/+2 0/0 ""' }
  
  # let(:sample3) { 'Mar 15 06:36:49 localhost haproxy[9367]: 127.0.0.1:38990 [15/Mar/2011:06:36:45.103] as-proxy mc-search-2 0/0/0/730/731 200 29404 - - --NN 2/54/54 0/0 {66.249.68.216} {} "GET /neighbor/26014153 HTTP/1.0" ' }

  describe '#parse_line' do
    it { should parse_line(sample1, 'an acess line').and_capture(
            :client_ip => '10.0.1.2',     :tq => 0.010,   :captured_request_cookie => nil,
            :timestamp => 20090206121414, :tw => 0.000,   :captured_response_cookie => nil,
            :frontend_name => 'http-in',  :tc => 0.030,   :clientside_persistence_cookie => nil,
            :backend_name => 'static',    :tr => 0.069,   :serverside_persistence_cookie => nil,
            :server_name => 'srv1',       :tt => 0.109,   :termination_event_code => nil,
            :status_code => 200,          :actconn => 1,  :terminated_session_state => nil,
            :bytes_read => 2750,          :feconn => 1,   :captured_request_headers => '{1wt.eu}',
            :backend_queue => 0,          :beconn => 1,   :captured_response_headers => nil,
            :retries => 0,                :srv_conn => 1, :srv_queue => 0,
            :http_request => 'GET /index.html HTTP/1.1')
    }
    
    it { should parse_line(sample2, 'a failed access line').and_capture(
            :timestamp => 20031015151906, :tq => nil,    :captured_request_cookie => nil,
            :server_name => '<NOSRV>',    :tw => nil,    :captured_response_cookie => nil,
            :bytes_read => 2750,          :tc => nil,    :clientside_persistence_cookie => nil,
            :retries => 2,                :tr => nil,    :serverside_persistence_cookie => nil,
            :http_request => nil,         :tt => 50.001, :termination_event_code => 'c',
                                                         :terminated_session_state => 'R',
                                                         :captured_request_headers => nil,
                                                         :captured_response_headers => nil)
    }
    
    # it { should parse_line(sample3, 'a third access line') }
    
    it { should_not parse_line('nonsense') }
  end
  
  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
    let(:snippet)    { log_snippet(sample1, sample2, 'nonsense') }
    
    it "should parse a log snippet without warnings" do
      log_parser.should_receive(:handle_request).exactly(2).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(snippet)
    end
  end
end
