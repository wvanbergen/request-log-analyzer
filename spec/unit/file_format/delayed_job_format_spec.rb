require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::DelayedJob do
  
  subject { RequestLogAnalyzer::FileFormat.load(:delayed_job) }

  it { should be_well_formed }
  it { should have_line_definition(:job_lock).capturing(:job) }
  it { should have_line_definition(:job_completed).capturing(:completed_job, :duration) }
  it { should have_line_definition(:job_lock_failed).capturing(:locked_job) }
  it { should have_line_definition(:job_failed).capturing(:failed_job, :attempts, :exception) }
  it { should have(3).report_trackers }

  describe '#parse_line' do
    let(:job_lock_sample)        { '* [JOB] acquiring lock on BackgroundJob::ThumbnailSaver' }
    let(:job_completed_sample)   { '* [JOB] BackgroundJob::ThumbnailSaver completed after 0.7932' }
    let(:job_lock_failed_sample) { '* [JOB] failed to acquire exclusive lock for BackgroundJob::ThumbnailSaver' }
    let(:job_failed_sample)      { "* [JOB] BackgroundJob::ThumbnailSaver failed with ActiveRecord::RecordNotFound: Couldn't find Design with ID=20413443 - 1 failed attempts" }  
    let(:summary_sample)         { '1 jobs processed at 1.0834 j/s, 0 failed ...' }

    it { should parse_line(job_lock_sample).as(:job_lock).and_capture(:job => 'BackgroundJob::ThumbnailSaver') }
    it { should parse_line(job_completed_sample).as(:job_completed).and_capture(:duration => 0.7932, :completed_job => 'BackgroundJob::ThumbnailSaver') }
    it { should parse_line(job_lock_failed_sample).as(:job_lock_failed).and_capture(:locked_job => 'BackgroundJob::ThumbnailSaver') }
    it { should parse_line(job_failed_sample).as(:job_failed).and_capture(:attempts => 1, :failed_job => 'BackgroundJob::ThumbnailSaver', :exception => 'ActiveRecord::RecordNotFound') }

    it { should_not parse_line(summary_sample, 'a summary line') }
    it { should_not parse_line('nonsense', 'a nonsense line') }
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) } 
    
    it "should parse a batch of completed jobs without warnings" do
      fragment = log_snippet(<<-EOLOG)
          * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
          * [JOB] BackgroundJob::ThumbnailSaver completed after 0.9114
          * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
          * [JOB] BackgroundJob::ThumbnailSaver completed after 0.9110
          2 jobs processed at 1.0832 j/s, 0 failed ...
      EOLOG

      log_parser.should_receive(:handle_request).twice
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(fragment)
    end
    
    it "should parse a batch with a failed job without warnings" do
      fragment = log_snippet(<<-EOLOG)
          * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
          * [JOB] BackgroundJob::ThumbnailSaver completed after 1.0627
          * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
          * [JOB] BackgroundJob::ThumbnailSaver failed with ActiveRecord::RecordNotFound: Couldn't find Design with ID=20413443 - 3 failed attempts
          Couldn't find Design with ID=20413443
          * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
          * [JOB] failed to acquire exclusive lock for BackgroundJob::ThumbnailSaver
          2 jobs processed at 1.4707 j/s, 1 failed ...
      EOLOG

      log_parser.should_receive(:handle_request).exactly(3).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_io(fragment)
    end
  end
end
