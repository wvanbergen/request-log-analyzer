require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Oink do

  subject { RequestLogAnalyzer::FileFormat.load(:oink) }
  
  it { should have_line_definition(:memory_usage).capturing(:pid, :memory) }
  it { should have_line_definition(:processing).capturing(:pid, :controller, :action, :ip) }
  it { should have_line_definition(:instance_type_counter).capturing(:pid, :instance_counts) }
  it { should have(12).report_trackers }

  describe '#parse_line' do
    let(:memory_usage_sample)          { 'Jun 18 11:27:36 derek rails[67783]: Memory usage: 714052 | PID: 67783' } 
    let(:processing_sample)            { 'Aug 14 21:16:30 derek rails[67783]: Processing PeopleController#index (for 1.1.1.1 at 2008-08-14 21:16:30) [GET]' }
    let(:instance_type_counter_sample) { "Dec 13 12:00:44 storenvy rails[26364]: Instantiation Breakdown: Total: 732 | User: 376 | Post: 323 | Comment: 32 | Blog: 1" }

    it "should parse a :memory_usage line correctly" do
      subject.should parse_line(memory_usage_sample).as(:memory_usage).and_capture(:pid => 67783, :memory => 714052)
    end
    
    it "should parse the PID from a :processing line correctly" do
      subject.should parse_line(processing_sample).as(:processing).and_capture(:pid => 67783, :controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET', :ip => '1.1.1.1')
    end

    it "should parse a :instance_type_counter correctly" do
      subject.should parse_line(instance_type_counter_sample).as(:instance_type_counter).and_capture(:pid => 26364, :instance_counts =>  {'Total' => 732, 'User' => 376, 'Post' => 323, 'Comment' => 32, 'Blog' => 1})
    end
  end
  
  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }
    
    context "Rails 2.2 style log" do
      it "should parse requests" do
        log_parser.should_receive(:handle_request).exactly(4).times
        log_parser.should_not_receive(:warn)
        log_parser.parse_file(log_fixture(:oink_22))
      end
      
      it "should not record :memory_diff on first request" do
        log_parser.parse_file(log_fixture(:oink_22)) do |request|
          request[:memory_diff].should == nil if log_parser.parsed_requests == 1
        end
      end
      
      it "should record :memory_diff of 2nd tracked PID" do
        log_parser.parse_file(log_fixture(:oink_22)) do |request|
          request[:memory_diff].should == 50000 * 1024 if log_parser.parsed_requests == 3
        end
      end
      
      it "should record :memory_diff of 1st tracked PID" do
        log_parser.parse_file(log_fixture(:oink_22)) do |request|
          request[:memory_diff].should == 30000 * 1024 if log_parser.parsed_requests == 4
        end
      end
    end
    
    context 'Rails 2.2 style log w/failure' do
      it "should parse requests" do
        log_parser.should_receive(:handle_request).exactly(4).times
        log_parser.should_not_receive(:warn)
        log_parser.parse_file(log_fixture(:oink_22_failure))
      end
      
      it "should ignore memory changes when a failure occurs" do
        log_parser.parse_file(log_fixture(:oink_22_failure)) do |request|
          request[:memory_diff].should == nil if log_parser.parsed_requests == 4
        end
      end
    end
  end
end
