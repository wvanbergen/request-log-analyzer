require File.dirname(__FILE__) + '/../spec_helper'

describe RequestLogAnalyzer::Mailer, 'mailer' do

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