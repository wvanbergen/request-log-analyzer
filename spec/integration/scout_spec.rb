require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/scouts_custom_output'

def capture_stdout_and_stderr_with_warnings_on
  $stdout, $stderr, warnings, $VERBOSE =
    StringIO.new, StringIO.new, $VERBOSE, true
  yield
  return $stdout.string, $stderr.string
ensure
  $stdout, $stderr, $VERBOSE = STDOUT, STDERR, warnings
end

describe RequestLogAnalyzer, 'when using the rla API like the scout plugin' do
  
  before(:each) do
    # prepare a place to capture the output
    sio = StringIO.new
    
    # place an IO object where I want RequestLogAnalyzer to read from
    open(log_fixture(:rails_1x)) do |log|
      completed_count = 0
      log.each do |line|
        completed_count += 1 if line =~ /\ACompleted\b/
        break if completed_count == 2  # skipping first two requests
      end
      
      # trigger the log parse
      @stdout, @stderr = capture_stdout_and_stderr_with_warnings_on do
        RequestLogAnalyzer::Controller.build(
          :output       => EmbeddedHTML,
          :file         => sio,
          :after        => Time.local(2008, 8, 14, 21, 16, 31),  # after 3rd req
          :source_files => log
        ).run!
      end
    end
    
    # read the resulting output
    @analysis = sio.string
  end
  
  it "should generate an analysis" do
    @analysis.should_not be_empty
  end
  
  it "should generate customized output using the passed Class" do
    credit = %r{<p>Powered by request-log-analyzer v\d+(?:\.\d+)+</p>\z}
    @analysis.should match(credit)
  end
  
  it "should skip requests before :after Time" do
    @analysis.should_not include("PeopleController#show")
  end
  
  it "should include requests after IO#pos and :after Time" do
    @analysis.should include("PeopleController#picture")
  end
  
  it "should skip requests before IO#pos" do
    @analysis.should_not include("PeopleController#index")
  end
  
  it "should not print to $stdout" do
    @stdout.should be_empty
  end
  
  it "should not print to $stderr (with warnings on)" do
    @stderr.should be_empty
  end

end
