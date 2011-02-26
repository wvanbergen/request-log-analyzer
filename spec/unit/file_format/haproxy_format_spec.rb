require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Haproxy do

  before(:each) do
    @file_format = RequestLogAnalyzer::FileFormat.load(:haproxy)
    @log_parser  = RequestLogAnalyzer::Source::LogParser.new(@file_format)
    @sample1 = 'Feb  6 12:14:14 localhost haproxy[14389]: 10.0.1.2:33317 [06/Feb/2009:12:14:14.655] http-in static/srv1 10/0/30/69/109 200 2750 - - ---- 1/1/1/1/0 0/0 {1wt.eu} {} "GET /index.html HTTP/1.1"'
    @sample2 = 'haproxy[18113]: 127.0.0.1:34549 [15/Oct/2003:15:19:06.103] px-http px-http/<NOSRV> -1/-1/-1/-1/+50001 408 +2750 - - cR-- 2/2/2/0/+2 0/0 ""'
  end

  it "should be a valid file format" do
    @file_format.should be_valid
  end

  it "should parse access lines and capture all of its fields" do
    @file_format.should have_line_definition(:haproxy).capturing(:client_ip, :accept_date, :frontend_name, :backend_name, :server_name, :tq, :tw, :tc, :tr, :tt, :status_code, :bytes_read, :captured_request_cookie, :captured_response_cookie, :termination_event_code, :terminated_session_state, :clientside_persistence_cookie, :serverside_persistence_cookie, :actconn, :feconn, :beconn, :srv_conn, :retries, :srv_queue, :backend_queue, :captured_request_headers, :captured_response_headers, :http_request)
  end

  it "should match the sample line" do
    @file_format.parse_line(@sample1).should include(:line_definition, :captures)
  end

  it "should not match a nonsense line" do
    @file_format.parse_line('dsadasdas dsaadsads dsaadsads').should be_nil
  end

  it "should parse and convert the sample fields correctly" do
    @log_parser.parse_io(StringIO.new(@sample1)) do |request|
      request[:client_ip].should                      == '10.0.1.2'
      request[:accept_date].should                    == 20090206121414
      request[:frontend_name].should                  == 'http-in'
      request[:backend_name].should                   == 'static'
      request[:server_name].should                    == 'srv1'
      request[:tq].should                             == 0.010
      request[:tw].should                             == 0.000
      request[:tc].should                             == 0.030
      request[:tr].should                             == 0.069
      request[:tt].should                             == 0.109
      request[:status_code].should                    == 200
      request[:bytes_read].should                     == 2750
      request[:captured_request_cookie].should        == nil
      request[:captured_response_cookie].should       == nil
      request[:termination_event_code].should         == nil
      request[:terminated_session_state].should       == nil
      request[:clientside_persistence_cookie].should  == nil
      request[:serverside_persistence_cookie].should  == nil
      request[:actconn].should                        == 1
      request[:feconn].should                         == 1
      request[:beconn].should                         == 1
      request[:srv_conn].should                       == 1
      request[:retries].should                        == 0
      request[:srv_queue].should                      == 0
      request[:backend_queue].should                  == 0
      request[:captured_request_headers].should       == '{1wt.eu}'
      request[:captured_response_headers].should      == nil
      request[:http_request].should                   == 'GET /index.html HTTP/1.1'
    end
  end

  it "should parse and convert edge case sample fields correctly" do
    @log_parser.parse_io(StringIO.new(@sample2)) do |request|
      request[:accept_date].should                    == 20031015151906
      request[:server_name].should                    == '<NOSRV>'
      request[:tq].should                             == nil
      request[:tw].should                             == nil
      request[:tc].should                             == nil
      request[:tr].should                             == nil
      request[:tt].should                             == 50.001
      request[:bytes_read].should                     == 2750
      request[:captured_request_cookie].should        == nil
      request[:captured_response_cookie].should       == nil
      request[:termination_event_code].should         == 'c'
      request[:terminated_session_state].should       == 'R'
      request[:clientside_persistence_cookie].should  == nil
      request[:serverside_persistence_cookie].should  == nil
      request[:retries].should                        == 2
      request[:captured_request_headers].should       == nil
      request[:captured_response_headers].should      == nil
      request[:http_request].should                   == nil
    end
  end

end
