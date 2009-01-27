require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RequestLogAnalyzer, 'running from command line' do
  
  include RequestLogAnalyzer::Spec::Helper
  
  TEMPORARY_DIRECTORY = "#{File.dirname(__FILE__)}/../fixtures"
  TEMP_DATABASE_FILE  = TEMPORARY_DIRECTORY + "/output.db"
  TEMP_REPORT_FILE    = TEMPORARY_DIRECTORY + "/report"
  
  RLA_BINARY = "#{File.dirname(__FILE__)}/../../bin/request-log-analyzer"

  before(:each) do
    File.unlink(TEMP_DATABASE_FILE) if File.exist?(TEMP_DATABASE_FILE)
    File.unlink(TEMP_REPORT_FILE) if File.exist?(TEMP_REPORT_FILE)    
  end

  after(:each) do
    File.unlink(TEMP_DATABASE_FILE) if File.exist?(TEMP_DATABASE_FILE)
    File.unlink(TEMP_REPORT_FILE) if File.exist?(TEMP_REPORT_FILE)    
  end
  
  it "should run well from the command line with the most important features" do  
    system("#{RLA_BINARY} #{log_fixture(:rails_1x)} --database #{TEMP_DATABASE_FILE} --select Controller PeopleController --file #{TEMP_REPORT_FILE} > /dev/null").should be_true   
  end
  
end