require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::DelayedJob do

  subject { RequestLogAnalyzer::FileFormat.load(:delayed_job21) }
  
  it { should be_well_formed }
  it { should have_line_definition(:job_lock).capturing(:timestamp, :job, :host, :pid) }
  it { should have_line_definition(:job_completed).capturing(:timestamp, :duration, :host, :pid) }
  it { should have(4).report_trackers }

  describe '#parse_line' do
    
    let(:job_lock_sample1) { "2010-05-17T17:37:34+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob" } 
    let(:job_lock_sample2) { "2010-05-17T17:37:34+0000: [Worker(delayed_job.0 host:hostname.co.uk pid:11888)] acquired lock on S3FileJob" } 
    let(:job_completed_sample1) { '2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] S3FileJob completed after 1.0676' }

    it { should parse_line(job_lock_sample1, 'with a single worker').as(:job_lock).and_capture(
          :timestamp => 20100517173734, :job => 'S3FileJob', :host => 'hostname.co.uk', :pid => 11888) }

    it { should parse_line(job_lock_sample2, 'with multiple workers').as(:job_lock).and_capture(
          :timestamp => 20100517173734, :job => 'S3FileJob', :host => 'hostname.co.uk', :pid => 11888) }

    it { should parse_line(job_completed_sample1).as(:job_completed).and_capture(
          :timestamp => 20100517173735, :duration => 1.0676, :host => 'hostname.co.uk', :pid => 11888, :job => 'S3FileJob') }
          
    it { should_not parse_line('nonsense', 'a nonsense line') }
  end
  
  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) } 
    
    it "should parse a batch of completed jobs without warnings" do
      fragment = log_snippet(<<-EOLOG)
        2010-05-17T17:36:44+0000: *** Starting job worker delayed_job host:hostname.co.uk pid:11888
        2010-05-17T17:37:34+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] S3FileJob completed after 1.0676
        2010-05-17T17:37:35+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:37+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] S3FileJob completed after 1.4407
        2010-05-17T17:37:37+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:44+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] S3FileJob completed after 6.9374
        2010-05-17T17:37:44+0000: [Worker(delayed_job host:hostname.co.uk pid:11888)] 3 jobs processed at 0.3163 j/s, 0 failed ...
        2010-05-19T11:47:26+0000: Exiting...
      EOLOG

      log_parser.should_receive(:handle_request).exactly(3).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(fragment)
    end
  end
end
