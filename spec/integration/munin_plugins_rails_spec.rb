require 'spec_helper'

describe RequestLogAnalyzer, 'when harvesting like munin-plugins-rails the YAML output' do
  
  before(:each) do 
    cleanup_temp_files!    
    run("#{log_fixture(:rails_1x)} --dump #{temp_output_file(:yaml)}")
    @rla = YAML::load(File.read(temp_output_file(:yaml)))
  end
  
  after(:each) do
    cleanup_temp_files!
  end
  
  it "should contain database times" do
    @rla["Database time"].each do |item|
      item[1][:min].should_not be_nil
      item[1][:max].should_not be_nil
      item[1][:hits].should_not be_nil
      item[1][:sum].should_not be_nil
    end
  end

  it "should contain request times" do
    @rla["Request duration"].each do |item|
      item[1][:min].should_not be_nil
      item[1][:max].should_not be_nil
      item[1][:hits].should_not be_nil
      item[1][:sum].should_not be_nil
    end
  end

  it "should contain failed requests" do
    @rla.keys.should include("Failed requests")
  end

  it "should contain Process blockers" do
    @rla.keys.should include("Process blockers (> 1 sec duration)")
  end

  it "should contain HTTP Methods" do
    @rla["HTTP methods"]["GET"].should_not be_nil
  end

  it "should contain HTTP Methods" do
    @rla["HTTP methods"]["GET"].should_not be_nil
  end

  it "should contain view rendering times" do
    @rla["View rendering time"].each do |item|
      item[1][:min].should_not be_nil
      item[1][:max].should_not be_nil
      item[1][:hits].should_not be_nil
      item[1][:sum].should_not be_nil
    end
  end

end
