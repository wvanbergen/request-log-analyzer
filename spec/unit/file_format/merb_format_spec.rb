require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Merb do

  subject { RequestLogAnalyzer::FileFormat.load(:merb) }
  
  it { should be_well_formed }
  it { should have_line_definition(:started).capturing(:timestamp) }
  it { should have_line_definition(:params).capturing(:controller, :action, :namespace) }
  it { should have_line_definition(:completed).capturing(:dispatch_time, :before_filters_time, :action_time, :after_filters_time) }
  it { should have(4).report_trackers }

  describe '#parse_line' do
    let(:started_sample)          { '~ Started request handling: Fri Aug 29 11:10:23 +0200 2008' }
    let(:prefixed_started_sample) { '~ Aug 31 18:35:24 typekit-web001 merb:  ~ Started request handling: Mon Aug 31 18:35:25 +0000 2009' }    
    let(:params_sample)           { '~ Params: {"_method"=>"delete", "authenticity_token"=>"[FILTERED]", "action"=>"delete", "controller"=>"session"}' }
    let(:completed_sample)        { '~ {:dispatch_time=>0.006117, :after_filters_time=>6.1e-05, :before_filters_time=>0.000712, :action_time=>0.005833}' }
    
    it { should parse_line(started_sample, 'without prefix').as(:started).and_capture(:timestamp => 20080829111023) }
    it { should parse_line(prefixed_started_sample, 'with prefix').as(:started).and_capture(:timestamp => 20090831183525) }
    it { should parse_line(params_sample).as(:params).and_capture(:controller => 'session', :action => 'delete', :namespace => nil) }
    it { should parse_line(completed_sample).as(:completed).and_capture(:dispatch_time => 0.006117, 
              :before_filters_time => 0.000712, :action_time => 0.005833, :after_filters_time => 6.1e-05) }

    it { should_not parse_line('~ nonsense', 'a nonsense line') }
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) } 

    it "should parse a log fragment correctly without warnings" do
      log_parser.should_receive(:handle_request).exactly(11).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_file(log_fixture(:merb))
    end
  end
end
