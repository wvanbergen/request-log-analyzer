require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::DelayedJob do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:delayed_job).should be_valid
  end

  describe '#parse_line' do
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:delayed_job)
    end

    it "should parse a :job_lock line correctly" do
      line = "* [JOB] acquiring lock on BackgroundJob::ThumbnailSaver"
      @file_format.should parse_line(line).as(:job_lock).and_capture(:job => 'BackgroundJob::ThumbnailSaver')
    end

    it "should parse a :job_completed line correctly" do
      line = '* [JOB] BackgroundJob::ThumbnailSaver completed after 0.7932'
      @file_format.should parse_line(line).as(:job_completed).and_capture(
        :duration => 0.7932, :completed_job => 'BackgroundJob::ThumbnailSaver')
    end
    
    it "should pase a :job_failed line correctly" do
      line = "* [JOB] BackgroundJob::ThumbnailSaver failed with ActiveRecord::RecordNotFound: Couldn't find Design with ID=20413443 - 1 failed attempts"
      @file_format.should parse_line(line).as(:job_failed).and_capture(:attempts => 1,
        :failed_job => 'BackgroundJob::ThumbnailSaver', :exception => 'ActiveRecord::RecordNotFound')
    end
    
    it "should parse a failed job lock line correctly" do
      line = "* [JOB] failed to acquire exclusive lock for BackgroundJob::ThumbnailSaver"
      @file_format.should parse_line(line).as(:job_lock_failed).and_capture(:locked_job => 'BackgroundJob::ThumbnailSaver')
    end
    
    # it "should pase a :batch_completed line correctly" do
    #   line = '1 jobs processed at 1.0834 j/s, 0 failed ...'
    #   @file_format.should parse_line(line).as(:batch_completed).and_capture(
    #     :mean_duration => 0.7932, :total_amount => 1, :failed_amount => 0) 
    # end

  end
  
  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:delayed_job))
    end
    
    it "should parse a batch of completed jobs without warnings" do
      fragment = "* [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
                  * [JOB] BackgroundJob::ThumbnailSaver completed after 0.9114
                  * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
                  * [JOB] BackgroundJob::ThumbnailSaver completed after 0.9110
                  2 jobs processed at 1.0832 j/s, 0 failed ..."

      request_counter.should_receive(:hit!).exactly(2).times
      @log_parser.should_not_receive(:warn)

      @log_parser.parse_io(StringIO.new(fragment)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::DelayedJob::Request)
      end
    end
    
    it "should parse a batch with a failed job without warnings" do
      fragment = "* [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
                  * [JOB] BackgroundJob::ThumbnailSaver completed after 1.0627
                  * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
                  * [JOB] BackgroundJob::ThumbnailSaver failed with ActiveRecord::RecordNotFound: Couldn't find Design with ID=20413443 - 3 failed attempts
                  Couldn't find Design with ID=20413443
                  * [JOB] acquiring lock on BackgroundJob::ThumbnailSaver
                  * [JOB] failed to acquire exclusive lock for BackgroundJob::ThumbnailSaver
                  2 jobs processed at 1.4707 j/s, 1 failed ..."

      request_counter.should_receive(:hit!).exactly(3).times
      @log_parser.should_not_receive(:warn)

      @log_parser.parse_io(StringIO.new(fragment)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::DelayedJob::Request)
      end
    end
  end
end

