$:.reject! { |e| e.include? 'TextMate' }
$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec/autorun'
require 'request_log_analyzer'

module RequestLogAnalyzer::Spec
end

# Include all files in the spec_helper directory
Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].each do |file| 
  require file 
end

Dir.mkdir("#{File.dirname(__FILE__)}/../tmp") unless File.exist?("#{File.dirname(__FILE__)}/../tmp")

Spec::Runner.configure do |config|
  config.include RequestLogAnalyzer::Spec::Matchers  
  config.include RequestLogAnalyzer::Spec::Mocks
  config.include RequestLogAnalyzer::Spec::Helpers  
  
  config.extend RequestLogAnalyzer::Spec::Macros  
end
