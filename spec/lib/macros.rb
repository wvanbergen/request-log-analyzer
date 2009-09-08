module RequestLogAnalyzer::Spec::Macros
  
  def test_databases
    require 'yaml'
    hash = YAML.load(File.read("#{File.dirname(__FILE__)}/../database.yml"))
    hash.inject({}) { |res, (name, h)| res[name] = h.map { |(k,v)| "#{k}=#{v}" }.join(';'); res  }
  end

end
