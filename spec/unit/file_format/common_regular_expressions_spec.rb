require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::CommonRegularExpressions do
  
  include RequestLogAnalyzer::FileFormat::CommonRegularExpressions
  
  describe '.timestamp' do
    
    it "should parse timestamps with a given format" do
      timestamp('%Y-%m-%dT%H:%M:%S%z').should =~ '2009-12-03T00:12:37+0100'
      timestamp('%Y-%m-%dT%H:%M:%S%z').should_not =~ '2009-12-03 00:12:37+0100'
      timestamp('%Y-%m-%dT%H:%M:%S%z').should_not =~ '2009-12-03T00:12:37'
    end
  end
  
  describe '.ip_address' do
    
    it "should parse IPv4 addresses" do
      ip_address.should =~ '127.0.0.1'
      ip_address.should =~ '255.255.255.255'
      
      ip_address.should_not =~ '2552.2552.2552.2552'
      ip_address.should_not =~ '127001'
      ip_address.should_not =~ ''
      ip_address.should_not =~ '-'
      ip_address.should_not =~ 'sub-host.domain.tld'
    end
    
    it "should pase IPv6 addresses" do
      ip_address.should =~ '::1'
      ip_address.should =~ '3ffe:1900:4545:3:200:f8ff:fe21:67cf'
      ip_address.should =~ '3ffe:1900:4545:3:200:f8ff:127.0.0.1'
      ip_address.should =~ '::3:200:f8ff:127.0.0.1'
      
      ip_address.should_not =~ 'qqqq:wwww:eeee:3q:200:wf8ff:fe21:67cf'
      ip_address.should_not =~ '3ffe44:1900f:454545:3:200:f8ff:ffff:5432'
    end
    
    it "should allow blank if true is given as parameter" do
      /^#{ip_address(true)}$/.should =~ ''
      /^#{ip_address(true)}$/.should_not =~ ' '
    end
    
    it "should allow a nil substitute if a string is given as parameter" do
      /^#{ip_address('-')}$/.should =~ '-'
      /^#{ip_address('-')}$/.should_not =~ ' -'
      /^#{ip_address('-')}$/.should_not =~ '--'
      /^#{ip_address('-')}$/.should_not =~ ''
    end
    
  end
end

