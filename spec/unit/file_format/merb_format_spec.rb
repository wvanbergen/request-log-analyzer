require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Merb do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:merb).should be_valid
  end

  describe '#parse_line' do
    before(:each) do
      @file_format = RequestLogAnalyzer::FileFormat.load(:merb)
    end
    
    it "should parse a :started line correctly" do
      line = '~ Started request handling: Fri Aug 29 11:10:23 +0200 2008'
      @file_format.should parse_line(line).as(:started).and_capture(:timestamp => 20080829111023)
    end

    it "should parse a prefixed :started line correctly" do
      line = '~ Aug 31 18:35:24 typekit-web001 merb:  ~ Started request handling: Mon Aug 31 18:35:25 +0000 2009'
      @file_format.should parse_line(line).as(:started).and_capture(:timestamp => 20090831183525)
    end

    it "should parse a :params line correctly" do
      line = '~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"delete", "controller"=>"session"}'
      @file_format.should parse_line(line).as(:params).and_capture(:controller => 'session', :action => 'delete', :namespace => nil)
    end

    it "should parse a :completed line correctly" do
      line = '~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}'
      @file_format.should parse_line(line).as(:completed).and_capture(:dispatch_time => 0.006117, 
        :before_filters_time => 0.000712, :action_time => 0.005833, :after_filters_time => 6.1e-05)
    end
  end

  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:merb))
    end

    it "should parse a stream and find valid Merb requests" do
      @log_parser.parse_file(log_fixture(:merb)) do |request|
        request.should be_kind_of(RequestLogAnalyzer::FileFormat::Merb::Request)
      end
    end
  
    it "should find 11 completed requests" do
      @log_parser.should_receive(:handle_request).exactly(11).times
      @log_parser.parse_file(log_fixture(:merb))
    end
  end
end
