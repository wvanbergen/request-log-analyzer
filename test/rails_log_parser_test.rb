require 'test/unit'

require "#{File.dirname(__FILE__)}/../lib/base/log_parser"
require "#{File.dirname(__FILE__)}/../lib/rails_analyzer/log_parser"

class RailsLogParserTest < Test::Unit::TestCase
  
  def fragment_file(number)
    "#{File.dirname(__FILE__)}/log_fragments/fragment_#{number}.log"
  end
  
  
  def test_rails_22_log_format
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(3)).each(:completed) do |request|
      count += 1
      assert_equal 0.614, request[:duration]  # should be 0.614
    end
    assert_equal 1, count  
  end
  
  def test_progress_messages
    log_file = fragment_file(1)
  
    finished_encountered = false
    file_size = File.size(log_file)
    
    previous_pos = -1
    parser = RailsAnalyzer::LogParser.new(log_file)
    parser.progress do |pos, total|
      assert_equal file_size, total
      if pos == :finished
        finished_encountered = true 
      else
        assert pos <= total
        assert pos > previous_pos
        previous_pos = pos
      end
    end
    
    # now parse the file
    parser.each(:started) { }
    
    assert finished_encountered, "A finished event should have been fired"
  end
  
  def test_parse_mongrel_log_fragment
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(1)).each(:started) { count += 1 }
    assert_equal 4, count
    
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(1)).each(:completed) { count += 1 }
    assert_equal 4, count    
    
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(1)).each(:started, :completed) { count += 1 }
    assert_equal 8, count    
  end
  
  def test_parse_syslog_fragment
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(2)).each(:started) { count += 1 }
    assert_equal 1, count
    
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(2)).each(:completed) { count += 1 }
    assert_equal 1, count    
    
    count = 0
    parser = RailsAnalyzer::LogParser.new(fragment_file(2)).each(:started, :completed) { count += 1 }
    assert_equal 2, count    
  end
  
  def test_parse_syslog_fragment_content
    # this test only works because there is only one requests in the fragment
    parser = RailsAnalyzer::LogParser.new(fragment_file(2)).each(:started) do |request|
      assert_equal "EmployeeController", request[:controller]
      assert_equal "index", request[:action]      
      assert_equal "GET", request[:method]
      assert_equal '10.1.1.33', request[:ip]
      assert_equal '2008-07-13 06:25:58', request[:timestamp]            
    end
  
    parser = RailsAnalyzer::LogParser.new(fragment_file(2)).each(:completed) do |request|
      assert_equal "http://example.com/employee.xml", request[:url]
      assert_equal 200, request[:status]
      assert_equal 0.21665, request[:duration]
      assert_equal 0.00926, request[:rendering]      
      assert_equal 0.0, request[:db]
    end
  
  end
  
end