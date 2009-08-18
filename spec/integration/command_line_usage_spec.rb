require File.dirname(__FILE__) + '/../spec_helper.rb'

describe RequestLogAnalyzer, 'running from command line' do
  
  before(:each) do
    cleanup_temp_files!
  end

  after(:each) do
    cleanup_temp_files!
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
    run("#{log_fixture(:rails_1x)} --file #{temp_output_file(:report)}")
    File.exist?(temp_output_file(:report)).should be_true
  end

  it "should write only ASCII characters to a file with the --file option" do  
    run("#{log_fixture(:rails_1x)} --file #{temp_output_file(:report)}")
    /^[\x00-\x7F]*$/.match(File.read(temp_output_file(:report))).should_not be_nil
  end

  it "should write HTML if --output HTML is provided" do
    output = run("#{log_fixture(:rails_1x)} --output HTML")
    output.any? { |line| /<html.*>/ =~ line}
  end
  
  it "should run with the --database option" do  
    run("#{log_fixture(:rails_1x)} --database #{temp_output_file(:database)}")
    File.exist?(temp_output_file(:database)).should be_true
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
  
  it "should dump the results to a YAML file" do
    run("#{log_fixture(:rails_1x)} --dump #{temp_output_file(:dump)}")
    File.exist?(temp_output_file(:dump)).should be_true
    YAML::load(File.read(temp_output_file(:dump))).should have_at_least(1).item
  end
  
end