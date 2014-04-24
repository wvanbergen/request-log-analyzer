require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::DelayedJob do

  subject { RequestLogAnalyzer::FileFormat.load(:delayed_job4) }

  it { should be_well_formed }
  it { should have_line_definition(:job_completed).capturing(:timestamp, :duration, :host, :pid, :job) }
  it { should have_line_definition(:job_failed).capturing(:timestamp, :host, :pid, :job, :attempts, :error) }
  it { should have_line_definition(:job_deleted).capturing(:timestamp, :host, :pid, :job, :failures) }
  it { should have(6).report_trackers }


  describe '#parse_line' do

    let(:job_completed_sample) { '2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob.create (id=534785) COMPLETED after 1.0676' }
    let(:job_failed_sample) { '2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob.create (id=534785) FAILED (0 prior attempts) with SocketError: getaddrinfo: Name or service not known' }
    let(:job_deleted_sample) { '2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob.create (id=534785) REMOVED permanently because of 25 consecutive failures' }

    it { should parse_line(job_completed_sample).as(:job_completed).and_capture(
          :timestamp => 20100517173735, :duration => 1.0676, :host => 'hostname.co.uk', :pid => 11888, :job => 'S3FileJob.create') }

    it { should parse_line(job_failed_sample).as(:job_failed).and_capture(
          :timestamp => 20100517173735, :host => 'hostname.co.uk', :pid => 11888, :job => 'S3FileJob.create (id=534785)', :attempts => 0, :error => "SocketError: getaddrinfo: Name or service not known") }

    it { should parse_line(job_deleted_sample).as(:job_deleted).and_capture(
          :timestamp => 20100517173735, :host => 'hostname.co.uk', :pid => 11888, :job => 'S3FileJob.create (id=534785)', :failures => 25) }

    it { should_not parse_line('nonsense', 'a nonsense line') }
  end


  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }

    it "should parse a batch of completed jobs without warnings" do
      fragment = log_snippet(<<-EOLOG)
        2010-05-17T17:36:44+0000: *** Starting job worker delayed_job host:hostname.co.uk pid:11888
        2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob (id=534785) COMPLETED after 1.0676
        2010-05-17T17:37:37+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob (id=534788) COMPLETED after 1.4407
        2010-05-17T17:37:44+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob (id=534789) COMPLETED after 6.9374
        2010-05-17T17:37:44+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] 3 jobs processed at 0.3163 j/s, 0 failed
        2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob.create (id=534786) FAILED (25 prior attempts) with SocketError: getaddrinfo: Name or service not known
        2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] Job S3FileJob.create (id=534799) REMOVED permanently because of 25 consecutive failures
        2010-05-19T11:47:26+0000: Exiting...
      EOLOG

      log_parser.should_receive(:handle_request).exactly(5).times
      log_parser.parse_io(fragment)
    end
  end
end
