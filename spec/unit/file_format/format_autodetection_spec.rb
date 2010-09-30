require 'spec_helper'

describe RequestLogAnalyzer::FileFormat do

  describe '.autodetect' do
    it "should autodetect a Merb log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:merb))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::Merb)
    end

    it "should autodetect a MySQL slow query log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:mysql_slow_query))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::Mysql)
    end

    it "should autodetect a Rails 1.x log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:rails_1x))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::Rails)
    end

    it "should autodetect a Rails 2.x log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:rails_22))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::RailsDevelopment)
    end

    it "should autodetect an Apache access log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:apache_common))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::Apache)
    end

    it "should autodetect a Rack access log" do
      file_format = RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:sinatra))
      file_format.should be_instance_of(RequestLogAnalyzer::FileFormat::Rack)
    end

    it "should not find any file format with a bogus file" do
      RequestLogAnalyzer::FileFormat.autodetect(log_fixture(:test_order)).should be_nil
    end
  end
end
