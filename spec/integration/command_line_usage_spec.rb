require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RequestLogAnalyzer, 'running from command line' do
  
  include RequestLogAnalyzer::Spec::Helper
  
  TEMPORARY_DIRECTORY = "#{File.dirname(__FILE__)}/../fixtures"
  TEMP_DATABASE_FILE  = TEMPORARY_DIRECTORY + "/output.db"
  TEMP_REPORT_FILE    = TEMPORARY_DIRECTORY + "/report"

  before(:each) do
    File.unlink(TEMP_DATABASE_FILE) if File.exist?(TEMP_DATABASE_FILE)
    File.unlink(TEMP_REPORT_FILE) if File.exist?(TEMP_REPORT_FILE)    
  end

  after(:each) do
    File.unlink(TEMP_DATABASE_FILE) if File.exist?(TEMP_DATABASE_FILE)
    File.unlink(TEMP_REPORT_FILE) if File.exist?(TEMP_REPORT_FILE)    
  end

  it "should find 4 requests in default mode" do  
    output = run("#{log_fixture(:rails_1x)}")
    output.detect { |line| /Parsed requests\:\s*4/ =~ line }.should_not be_nil
  end

  it "should find 3 requests with a --select option" do  
    output = run("#{log_fixture(:rails_1x)} --select controller PeopleController")
    output.detect { |line| /Parsed requests\:\s*4/ =~ line }.should_not be_nil
  end

  it "should find 1 requests with a --reject option" do  
    output = run("#{log_fixture(:rails_1x)} --reject controller PeopleController")
    output.detect { |line| /Parsed requests\:\s*4/ =~ line }.should_not be_nil
  end
  
  it "should write output to a file with the --file option" do  
    run("#{log_fixture(:rails_1x)} --file #{TEMP_REPORT_FILE}")
    File.exist?(TEMP_REPORT_FILE).should be_true
  end

  it "should write only ASCII characters to a file with the --file option" do  
    run("#{log_fixture(:rails_1x)} --file #{TEMP_REPORT_FILE}")
    /^[\x00-\x7F]*$/.match(File.read(TEMP_REPORT_FILE)).should be_true
  end

  it "should write HTML if --output HTML is provided" do
    output = run("#{log_fixture(:rails_1x)} --output HTML")
    output.any? { |line| /<html.*>/ =~ line}
  end
  
  it "should run with the --database option" do  
    run("#{log_fixture(:rails_1x)} --database #{TEMP_DATABASE_FILE}")
    File.exist?(TEMP_DATABASE_FILE).should be_true
  end

  it "should use no colors in the report with the --boring option" do  
    output = run("#{log_fixture(:rails_1x)} --boring")
    output.any? { |line| /\e/ =~ line }.should be_false
  end
  
  it "should use only ASCII characters in the report with the --boring option" do  
    output = run("#{log_fixture(:rails_1x)} --boring")
    output.all? { |line| /^[\x00-\x7F]*$/ =~ line }.should be_true
  end
  
  it "should parse a Merb file if --format merb is set" do  
    output = run("#{log_fixture(:merb)} --format merb")
    output.detect { |line| /Parsed requests\:\s*11/ =~ line }.should_not be_nil   
  end  
  
end