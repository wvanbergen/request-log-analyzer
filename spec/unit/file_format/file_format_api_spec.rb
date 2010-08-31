require 'spec_helper'

describe RequestLogAnalyzer::FileFormat do

  describe ".format_definition" do

    before(:each) do
      @first_file_format  = Class.new(RequestLogAnalyzer::FileFormat::Base)
      @second_file_format = Class.new(RequestLogAnalyzer::FileFormat::Base)
    end

    it "should specify line definitions directly within the file_format" do
      @first_file_format.format_definition.direct_test :regexp => /test/
      @first_file_format.should have_line_definition(:direct_test)
    end

    it "specify lines with a block for the format definition" do
      @first_file_format.format_definition do |format|
        format.block_test :regexp => /test (\w+)/, :captures => [{:name => :tester, :type => :string}]
      end

      @first_file_format.should have_line_definition(:block_test).capturing(:tester)
    end

    it "should specify a line with a block" do
      @first_file_format.format_definition.hash_test do |line|
        line.regexp   = /test/
        line.captures = []
      end

      @first_file_format.should have_line_definition(:hash_test)
    end

    it "should define lines only for its own language" do
      @first_file_format.format_definition.first   :regexp => /test 123/
      @second_file_format.format_definition.second :regexp => /test 456/

      @first_file_format.should      have_line_definition(:first)
      @first_file_format.should_not  have_line_definition(:second)
      @second_file_format.should_not have_line_definition(:first)
      @second_file_format.should     have_line_definition(:second)
    end
  end

  describe ".load" do

    it "should return an instance of a FileFormat class" do
      @file_format = RequestLogAnalyzer::FileFormat.load(TestingFormat)
      @file_format.should be_kind_of(TestingFormat)
    end

    it "should return itself if it already is a FileFormat::Base instance" do
      @file_format = RequestLogAnalyzer::FileFormat.load(testing_format)
      @file_format.should be_kind_of(TestingFormat)
    end

    it "should load a predefined file format from the /file_format dir" do
      @file_format = RequestLogAnalyzer::FileFormat.load(:rails)
      @file_format.should be_kind_of(RequestLogAnalyzer::FileFormat::Rails)
    end

    it "should load a provided format file" do
      format_filename = File.expand_path('../../lib/testing_format.rb', File.dirname(__FILE__))
      @file_format = RequestLogAnalyzer::FileFormat.load(format_filename)
      @file_format.should be_kind_of(TestingFormat)
    end
    
  end
end