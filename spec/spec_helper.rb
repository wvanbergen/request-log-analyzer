require 'rubygems'
require 'bundler/setup'

require 'rspec'
require 'request_log_analyzer'
require 'stringio'

module RequestLogAnalyzer::RSpec
end

# Include all files in the spec_helper directory
Dir[File.dirname(__FILE__) + "/lib/**/*.rb"].each do |file|
  require file
end

Dir.mkdir("#{File.dirname(__FILE__)}/../tmp") unless File.exist?("#{File.dirname(__FILE__)}/../tmp")

RSpec.configure do |config|
  config.include RequestLogAnalyzer::RSpec::Matchers
  config.include RequestLogAnalyzer::RSpec::Mocks
  config.include RequestLogAnalyzer::RSpec::Helpers

  config.extend RequestLogAnalyzer::RSpec::Macros
end
