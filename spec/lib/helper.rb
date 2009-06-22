module RequestLogAnalyzer::Spec::Helper
  
  include RequestLogAnalyzer::Spec::Mocks

  # Create or return a new TestingFormat
  def testing_format
    @testing_format ||= TestingFormat.new
  end
  
  # Load a log file from the fixture folder
  def log_fixture(name, extention = "log")
    File.dirname(__FILE__) + "/../fixtures/#{name}.#{extention}"
  end

  # Request loopback
  def request(fields, format = testing_format)
    if fields.kind_of?(Array)
      format.request(*fields)
    else
      format.request(fields)      
    end
  end

  # Run a specific command
  # Used to call request-log-analyzer through binary
  def run(arguments)
    binary = "#{File.dirname(__FILE__)}/../../bin/request-log-analyzer"
    arguments = arguments.join(' ') if arguments.kind_of?(Array)
    
    output = []
    IO.popen("#{binary} #{arguments}") do |pipe|
      output = pipe.readlines
    end
    $?.exitstatus.should == 0
    output
  end
end
