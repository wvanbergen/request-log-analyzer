require 'test/unit'

require "#{File.dirname(__FILE__)}/../lib/base/log_parser"
require "#{File.dirname(__FILE__)}/../lib/merb_analyzer/log_parser"

class LogParserTest < Test::Unit::TestCase
  
  def fragment_file(number)
    "#{File.dirname(__FILE__)}/log_fragments/merb_#{number}.log"
  end
  
  def test_parse_started_merb_fragment
    requests = []
    parser = MerbAnalyzer::LogParser.new(fragment_file(1)).each(:started) do |request|
      requests << request
    end
    assert_equal requests[0][:timestamp], "Fri Aug 29 11:10:23 +0200 2008"
  end

  def test_parse_completed_merb_fragment
    requests = []
    parser = MerbAnalyzer::LogParser.new(fragment_file(1)).each(:completed) do |request|
      requests << request
    end
    
    assert_equal requests[0][:action_time], 0.241652
  end

  def test_parse_params_merb_fragment
    requests = []
    parser = MerbAnalyzer::LogParser.new(fragment_file(1)).each(:params) do |request|
      requests << request
    end
    
    assert_match '"controller"=>"session"', requests[0][:raw_hash]
    assert_match '"action"=>"destroy"', requests[0][:raw_hash]
  end
  
end