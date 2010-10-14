module RequestLogAnalyzer::RSpec::Macros

  def test_databases
    require 'yaml'
    hash = YAML.load(File.read("#{File.dirname(__FILE__)}/../database.yml"))
    hash.inject({}) { |res, (name, h)| res[name] = h.map { |(k,v)| "#{k}=#{v}" }.join(';'); res  }
  end

  # Create or return a new TestingFormat
  def testing_format
    @testing_format ||= TestingFormat.create
  end

  def default_orm_class_names
    ['Warning', 'Request', 'Source']
  end

end
