require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RequestLogAnalyzer, 'when using the rla API like the scout plugin' do
  
  before(:each) do 
    @summary = StringIO.new
    RequestLogAnalyzer::Controller.build(
      :output       => :HTML,
      :file         => @summary,
      :source_files => "#{log_fixture(:rails_1x)}",
      :no_progress  => true
    ).run!
  end
  
  it "should generate a summary" do
    @summary.string.should_not be_nil
  end

end
