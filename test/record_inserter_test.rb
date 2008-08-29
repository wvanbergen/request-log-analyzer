require 'test/unit'

require "#{File.dirname(__FILE__)}/../lib/rails_analyzer/log_parser"
require "#{File.dirname(__FILE__)}/../lib/rails_analyzer/record_inserter"

class RecordInserterTest < Test::Unit::TestCase
  
  def fragment_file(number)
    "#{File.dirname(__FILE__)}/log_fragments/fragment_#{number}.log"
  end
  
  def setup
    File.delete('_tmp.db') if File.exist?('_tmp.db')
  end
  
  def teardown
    File.delete('_tmp.db') if File.exist?('_tmp.db')
  end
  
  def test_insert_log_fragment
    
    db = RailsAnalyzer::RecordInserter.insert_batch_into('_tmp.db') do |batch|
      RailsAnalyzer::LogParser.new(fragment_file(1)).each { |request| batch.insert(request) }
    end

    assert_equal 4, db.database.get_first_value("SELECT COUNT(*) FROM started_requests").to_i
    assert_equal 4, db.database.get_first_value("SELECT COUNT(*) FROM completed_requests").to_i 
  end
  
  def test_insert_multiple_fragments
    RailsAnalyzer::RecordInserter.insert_batch_into('_tmp.db') do |batch|
      RailsAnalyzer::LogParser.new(fragment_file(1)).each { |request| batch.insert(request) }
    end

    db = RailsAnalyzer::RecordInserter.insert_batch_into('_tmp.db') do |batch|
      RailsAnalyzer::LogParser.new(fragment_file(2)).each { |request| batch.insert(request) }
    end
    assert_equal 5, db.database.get_first_value("SELECT COUNT(*) FROM started_requests").to_i
    assert_equal 5, db.database.get_first_value("SELECT COUNT(*) FROM completed_requests").to_i    
  end
  
end