require 'spec_helper'

describe RequestLogAnalyzer::Mailer, 'mailer' do

  it "should initialize correctly" do
    @mailer = RequestLogAnalyzer::Mailer.new('alfa@beta.com', 'localhost', :debug => true) 
    @mailer.host.should eql("localhost")
    @mailer.port.should eql(25)
  end
  
  it "should allow alternate port settings" do
    @mailer = RequestLogAnalyzer::Mailer.new('alfa@beta.com', 'localhost:2525', :debug => true) 
    @mailer.host.should eql("localhost")
    @mailer.port.should eql("2525")
  end

  it "should store printed data" do
    @mailer = RequestLogAnalyzer::Mailer.new('alfa@beta.com', 'localhost', :debug => true)

    @mailer << 'test1'
    @mailer.puts 'test2'
    
    @mailer.data.should eql(['test1', 'test2'])
  end

  it "should send mail" do
    @mailer = RequestLogAnalyzer::Mailer.new('alfa@beta.com', 'localhost', :debug => true)

    @mailer << 'test1'
    @mailer.puts 'test2'

    mail = @mailer.mail
    
    mail[0].should include("contact@railsdoctors.com")
    mail[0].should include("test1")
    mail[0].should include("test2")

    mail[1].should include("contact@railsdoctors.com")
    mail[2].should include("alfa@beta.com")
  end

end