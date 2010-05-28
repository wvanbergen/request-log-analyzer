require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::DelayedJob do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:delayed_job).should be_valid
  end

  describe '#parse_line' do
    
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:delayed_job2)
    end

    it "should parse a :job_lock line correctly" do
      line = "2010-05-17T17:37:34+0000: * [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob"
      @file_format.should parse_line(line).as(:job_lock).and_capture(:timestamp => 20100517173734,
                                    :job => 'S3FileJob', :host => 'hostname.co.uk', :pid => 11888)
    end

    it "should parse a :job_completed line correctly" do
      line = '2010-05-17T17:37:35+0000: * [JOB] delayed_job host:hostname.co.uk pid:11888 completed after 1.0676'
      @file_format.should parse_line(line).as(:job_completed).and_capture(:timestamp => 20100517173735,
                                    :duration => 1.0676, :host => 'hostname.co.uk', :pid => 11888)
    end
  end
  
  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:delayed_job2))
    end
    
    it "should parse a batch of completed jobs without warnings" do
      fragment = <<-EOLOG
        2010-05-17T17:36:44+0000: *** Starting job worker delayed_job host:hostname.co.uk pid:11888
        2010-05-17T17:37:34+0000: * [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:35+0000: * [JOB] delayed_job host:hostname.co.uk pid:11888 completed after 1.0676
        2010-05-17T17:37:35+0000: * [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:37+0000: * [JOB] delayed_job host:hostname.co.uk pid:11888 completed after 1.4407
        2010-05-17T17:37:37+0000: * [Worker(delayed_job host:hostname.co.uk pid:11888)] acquired lock on S3FileJob
        2010-05-17T17:37:44+0000: * [JOB] delayed_job host:hostname.co.uk pid:11888 completed after 6.9374
        2010-05-17T17:37:44+0000: 3 jobs processed at 0.3163 j/s, 0 failed ...
        2010-05-19T11:47:26+0000: Exiting...
      EOLOG

      request_counter.should_receive(:hit!).exactly(3).times
      @log_parser.should_not_receive(:warn)

      @log_parser.parse_io(StringIO.new(fragment)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::DelayedJob2::Request)
      end
    end
  end
end
