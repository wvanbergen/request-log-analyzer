module RequestLogAnalyzer::Spec::Helper
  
  include RequestLogAnalyzer::Spec::Mocks


  def testing_format
    @testing_format ||= TestingFormat.new
  end
  
  def log_fixture(name)
    File.dirname(__FILE__) + "/../fixtures/#{name}.log"
  end

  def request(fields, format = testing_format)
    if fields.kind_of?(Array)
      format.request(*fields)
    else
      format.request(fields)      
    end
  end

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
