require File.dirname(__FILE__) + '/spec_helper'
require 'request_log_analyzer/log_processor'

describe RequestLogAnalyzer::LogProcessor, 'anonymization' do

  include TestFileFormat
  
  before(:each) do
    @log_anonymizer = RequestLogAnalyzer::LogProcessor.new(TestFileFormat, :anonymize, {})
    @alternate_log_anonymizer = RequestLogAnalyzer::LogProcessor.new(TestFileFormat, :anonymize, {:keep_junk_lines => true, :discard_teaser_lines => true})
  end
  
  it "should keep a junk line if :keep_junk_lines is true" do
    @alternate_log_anonymizer.anonymize_line("junk line\n").should == "junk line\n"
  end
  
  it "should remove a junk line" do
    @log_anonymizer.anonymize_line("junk line\n").should be_empty
  end

  it "should keep a teaser line intact" do
    @log_anonymizer.anonymize_line("processing 1234\n").should == "processing 1234\n"
  end
  
  it "should discard a teaser line if discard_teaser_line is true" do
    @alternate_log_anonymizer.anonymize_line("processing 1234\n").should be_empty
  end
  
  it "should keep a matching line intact if no anonymizing is declared" do
    @alternate_log_anonymizer.anonymize_line("finishing request 130\n").should == "finishing request 130\n"
  end  

  it "should anonymize values completely if requested" do
    @alternate_log_anonymizer.anonymize_line("testing is great\n").should == "testing is ***\n"
  end  
  
  it "should anonymize values slightly if requested" do
    @alternate_log_anonymizer.anonymize_line("finishing request 130\n").should =~ /^finishing request 1\d\d\n$/
  end
end

describe RequestLogAnalyzer::LogProcessor, 'stripping log files' do

  include TestFileFormat
  
  before(:each) do
    @log_stripper = RequestLogAnalyzer::LogProcessor.new(TestFileFormat, :strip, {})
  end
  
  it "should remove a junk line" do
    @log_stripper.strip_line("junk line\n").should be_empty
  end

  it "should keep a teaser line intact" do
    @log_stripper.strip_line("processing 1234\n").should be_empty
  end
end