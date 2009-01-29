class TestingFormat < RequestLogAnalyzer::FileFormat::Base

  format_definition.first do |line|
    line.header = true
    line.teaser = /processing /
    line.regexp = /processing request (\d+)/
    line.captures = [{ :name => :request_no, :type => :integer }]    
  end
  
  format_definition.test do |line|
    line.teaser = /testing /
    line.regexp = /testing is (\w+)(?: in (\d+\.\d+)ms)?/
    line.captures = [{ :name => :test_capture, :type => :test_type },
                     { :name => :duration, :type => :duration, :unit => :msec }]
  end
  
  format_definition.eval do |line|
    line.regexp = /evaluation (\{.*\})/
    line.captures = [{ :name => :evaluated, :type => :eval }]
  end 
  
  format_definition.last do |line|
    line.footer = true
    line.teaser = /finishing /
    line.regexp = /finishing request (\d+)/
    line.captures = [{ :name => :request_no, :type => :integer }]
  end
  
  report do |analyze|
    analyze.frequency :test_capture, :title => 'What is testing exactly?'
  end
  
  class Request < RequestLogAnalyzer::Request
    def convert_test_type(value, definition)
      "Testing is #{value}"
    end
  end
  
end