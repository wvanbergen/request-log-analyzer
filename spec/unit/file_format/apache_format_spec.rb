require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Apache do

  describe '.access_line_definition' do
    let(:format_string) { '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %T' }
    let(:line_definition) { RequestLogAnalyzer::FileFormat::Apache.access_line_definition(format_string) }

    it "should create a Regexp to match the line" do
      line_definition.regexp.should be_kind_of(Regexp)
    end

    it "should create a list of captures for the values in the lines" do
      line_definition.captures.should have(12).items
    end

    it "should make it a header line" do
      line_definition.should be_header
    end

    it "should make it a footer line" do
      line_definition.should be_footer
    end

    it "should capture :duration" do
      line_definition.captures?(:duration).should be_true
    end
  end
  
  describe '.access_line_definition' do
    it "should parse values in microseconds when no argument is given to %D" do
      format = RequestLogAnalyzer::FileFormat::Apache.create('%D')
      format.should parse_line('12345').and_capture(:duration => 0.012345)
    end
    
    it "should parse values in microseconds when micro is given as argument to %D" do
      format = RequestLogAnalyzer::FileFormat::Apache.create('%{micro}D')
      format.should parse_line('12345').and_capture(:duration => 0.012345)
    end
    
    it "should parse values in microseconds when micro is given as argument to %D" do
      format = RequestLogAnalyzer::FileFormat::Apache.create('%{milli}D')
      format.should parse_line('12345').and_capture(:duration => 12.345)
    end
  end

  describe '.create' do
    let(:format_string) { '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i"' }
    subject { RequestLogAnalyzer::FileFormat::Apache.create(format_string) }

    it { should be_well_formed }
    it { should have_line_definition(:access).capturing(:timestamp, :remote_host, :bytes_sent, :http_method, :path, :http_version, :http_status) }
    it { should have(8).report_trackers }
  end

  context '"Common" access log parsing' do
    subject { RequestLogAnalyzer::FileFormat.load(:apache, :common) } 
    
    it { should be_well_formed }
    it { should have_line_definition(:access).capturing(:remote_host, :remote_logname, :user, :timestamp, :http_status, :http_method, :http_version, :bytes_sent) }
    it { should have(6).report_trackers }
    
    describe '#parse_line' do
      
      let(:sample1) { '1.129.119.13 - - [08/Sep/2009:07:54:09 -0400] "GET /profile/18543424 HTTP/1.0" 200 8223' }
      let(:sample2) { '1.82.235.29 - - [08/Sep/2009:07:54:05 -0400] "GET /gallery/fresh?page=23&per_page=16 HTTP/1.1" 200 23414' }
      
      it { should parse_line(sample1, 'a sample line').and_capture(
            :remote_host    => '1.129.119.13', :remote_logname => nil, :user        => nil,
            :timestamp      => 20090908075409, :http_status    => 200, :http_method => 'GET',
            :http_version   => '1.0',          :bytes_sent     => 8223)
      }
      
      it { should parse_line(sample2, 'another sample line').and_capture(
            :remote_host    => '1.82.235.29',  :remote_logname => nil, :user        => nil,
            :timestamp      => 20090908075405, :http_status    => 200, :http_method => 'GET',
            :http_version   => '1.1',          :bytes_sent     => 23414)
      }
      
      it { should_not parse_line('nonsense', 'a nonsense line')}
    end
    
    describe '#parse_io' do
      let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
      
      it "should parse a log snippet successfully without warnings" do
        log_parser.should_receive(:handle_request).exactly(10).times
        log_parser.should_not_receive(:warn)
        log_parser.parse_file(log_fixture(:apache_common))
      end
    end
  end

  context '"Combined" access log parsing' do
    subject { RequestLogAnalyzer::FileFormat.load(:apache, :combined) } 
    
    it { should be_well_formed }
    it { should have_line_definition(:access).capturing(:remote_host, :remote_logname, :user, :timestamp, :http_status, :http_method, :http_version, :bytes_sent, :referer, :user_agent) }
    it { should have(8).report_trackers }
    
    describe '#parse_line' do
      let(:sample1) { '69.41.0.45 - - [02/Sep/2009:12:02:40 +0200] "GET //phpMyAdmin/ HTTP/1.1" 404 209 "-" "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)"' }
      let(:sample2) { '0:0:0:0:0:0:0:1 - - [02/Sep/2009:05:08:33 +0200] "GET / HTTP/1.1" 200 30 "-" "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9"' }
      
      it { should parse_line(sample1, 'with IPv4 address').and_capture(
            :remote_host  => '69.41.0.45',   :remote_logname => nil, :user        => nil,
            :timestamp    => 20090902120240, :http_status    => 404, :http_method => 'GET',
            :http_version => '1.1',          :bytes_sent     => 209, :referer     => nil,
            :user_agent   => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)')
      }
      
      it { should parse_line(sample2, 'with IPv6 address').and_capture(
            :remote_host  => '0:0:0:0:0:0:0:1', :remote_logname => nil, :user        => nil,
            :timestamp    => 20090902050833,    :http_status    => 200, :http_method => 'GET',
            :http_version => '1.1',             :bytes_sent     => 30,  :referer     => nil,
            :user_agent   => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9')
      }
      
      it { should_not parse_line('nonsense', 'a nonsense line')}
    end
    
    describe '#parse_io' do
      let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
      
      it "should parse a log snippet successfully without warnings" do
        log_parser.should_receive(:handle_request).exactly(5).times
        log_parser.should_not_receive(:warn)
        log_parser.parse_file(log_fixture(:apache_combined))
      end
    end
  end
end
