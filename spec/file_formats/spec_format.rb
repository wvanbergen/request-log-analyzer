class SpecFormat < RequestLogAnalyzer::FileFormat::Base

  format_definition.first do |line|
    line.header = true
    line.teaser = /processing /
    line.regexp = /processing request (\d+)/
    line.captures = [{ :name => :request_no, :type => :integer, :anonymize => :slightly }]    
  end
  
  format_definition.test do |line|
    line.teaser = /testing /
    line.regexp = /testing is (\w+)/
    line.captures = [{ :name => :test_capture, :type => :string, :anonymize => true}]
  end
  
  format_definition.last do |line|
    line.footer = true
    line.teaser = /finishing /
    line.regexp = /finishing request (\d+)/
    line.captures = [{ :name => :request_no, :type => :integer}]
  end
  
  report do |analyze|
    analyze.category :test_capture, :title => 'What is testing exactly?'
  end
  
end