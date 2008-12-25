$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'

module RequestLogAnalyzerSpecHelper
  
  def log_fixture(name)
    File.dirname(__FILE__) + "/fixtures/#{name}.log"
  end
  
end