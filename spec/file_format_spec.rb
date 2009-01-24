require File.dirname(__FILE__) + '/spec_helper'

describe RequestLogAnalyzer::FileFormat, :format_definition do
  
  before(:each) do
    @first_file_format = Class.new(RequestLogAnalyzer::FileFormat::Base)
    @second_file_format = Class.new(RequestLogAnalyzer::FileFormat::Base)
  end
    
  it "should specify lines with a hash" do
    
    @first_file_format.new.should have(0).line_definitions
        
    @first_file_format.format_definition do |line|
      line.hash_test :regexp => /test/, :captures => []
    end
    
    @format_instance = @first_file_format.new
    @format_instance.should have(1).line_definitions
    @format_instance.line_definitions[:hash_test].should_not be_nil
  end
  
  it "should specift lines directly" do
    @first_file_format.new.should have(0).line_definitions    
    
    @first_file_format.format_definition.direct_test do |line|
      line.regexp   = /test/
    end 
    
    @first_file_format.new.line_definitions[:direct_test].should_not be_nil
  end
 
  it "specify lines with a block" do
    
    @first_file_format.new.should have(0).line_definitions    
    
    @first_file_format.format_definition do |format|
      format.block_test do |line|
        line.regexp   = /test/
        line.captures = []
      end
    end 
    
    @first_file_format.new.line_definitions[:block_test].should_not be_nil
  end
  
  it "should define lines only for itself" do
    
    @first_file_format.format_definition do |line|
      line.first_test :regexp => /test/, :captures => []
    end
    

    @second_file_format.format_definition do |line|
      line.second_test :regexp => /test/, :captures => []
    end

    @first_file_format.line_definer.should_not eql(@second_file_format.line_definer)
    @first_file_format.new.should have(1).line_definitions    
    @second_file_format.new.line_definitions[:second_test].should_not be_nil
  end  
end

describe RequestLogAnalyzer::FileFormat, :load do

  include RequestLogAnalyzerSpecHelper

  it "should load a predefined file format from the /file_format dir" do
    @file_format = RequestLogAnalyzer::FileFormat.load(:rails)
    @file_format.should be_kind_of(RequestLogAnalyzer::FileFormat::Rails)
  end
  
  it "should load a provided format file" do
    @file_format = RequestLogAnalyzer::FileFormat.load(format_file(:spec_format))
    @file_format.should be_kind_of(SpecFormat)
  end
  
end