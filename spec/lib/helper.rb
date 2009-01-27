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
end
