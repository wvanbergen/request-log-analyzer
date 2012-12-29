require 'spec_helper'

describe RequestLogAnalyzer, 'running from command line' do

  before(:each) do
    cleanup_temp_files!
  end

  after(:each) do
    cleanup_temp_files!
  end

  it "should find 4 requests in default mode" do
    output = run("#{log_fixture(:rails_1x)}")
    output.any? { |line| /^Parsed requests\:\s*4\s/ =~ line }.should be_true
  end

  it "should find 2 requests when parsing a compressed file" do
    output = run("#{log_fixture(:decompression, :tgz)}")
    output.any? { |line| /^Parsed requests\:\s*2\s/ =~ line }.should be_true
  end

  it "should skip 1 requests with a --select option" do
    output = run("#{log_fixture(:rails_1x)} --select controller PeopleController")
    output.any? { |line| /^Skipped requests\:\s*1\s/ =~ line }.should be_true
  end

  it "should skip 3 requests with a --reject option" do
    output = run("#{log_fixture(:rails_1x)} --reject controller PeopleController")
    output.any? { |line| /^Skipped requests\:\s*3\s/ =~ line }.should be_true
  end

  it "should not write output with the --silent option" do
    output = run("#{log_fixture(:rails_1x)} --silent --file #{temp_output_file(:report)}")
    output.should be_empty
    File.exist?(temp_output_file(:report)).should be_true
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
    output.any? { |line| /<html[^>]*>/ =~ line}.should be_true
  end

  it "should run with the --database option" do
    run("#{log_fixture(:rails_1x)} --database #{temp_output_file(:database)}")
    File.exist?(temp_output_file(:database)).should be_true
  end

  it "should use no colors in the report with the --boring option" do
    output = run("#{log_fixture(:rails_1x)} --boring --format rails")
    output.any? { |line| /\e/ =~ line }.should be_false
  end

  it "should use only ASCII characters in the report with the --boring option" do
    output = run("#{log_fixture(:rails_1x)} --boring")
    output.all? { |line| /^[\x00-\x7F]*$/ =~ line }.should be_true
  end

  it "should parse a Merb file if --format merb is set" do
    output = run("#{log_fixture(:merb)} --format merb")
    output.any? { |line| /Parsed requests\:\s*11/ =~ line }.should be_true
  end

  it "should parse a Apache access log file if --apache-format is set" do
    output = run("#{log_fixture(:apache_combined)} --apache-format combined")
    output.any? { |line| /Parsed requests\:\s*5/ =~ line }.should be_true
  end

  it "should dump the results to a YAML file" do
    run("#{log_fixture(:rails_1x)} --yaml #{temp_output_file(:yaml)}")
    File.exist?(temp_output_file(:yaml)).should be_true
    YAML.load(File.read(temp_output_file(:yaml))).should have_at_least(1).item
  end

  it "should parse 4 requests from the standard input" do
    output = run("--format rails - < #{log_fixture(:rails_1x)}")
    output.any? { |line| /^Parsed requests\:\s*4\s/ =~ line }.should be_true
  end

  it "should accept a directory as a commandline option" do
    output = run("#{log_directory_fixture("s3_logs")} --format amazon_s3")
    output.any? { |line| /^Parsed requests:\s*8\s/ =~ line }.should be_true
  end
end
