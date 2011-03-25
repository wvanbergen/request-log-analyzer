require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::CommonRegularExpressions do
  
  include RequestLogAnalyzer::FileFormat::CommonRegularExpressions

  describe '.timestamp' do
    it "should parse timestamps with a given format" do
      anchored(timestamp('%Y-%m-%dT%H:%M:%S%z')).should =~ '2009-12-03T00:12:37+0100'
      anchored(timestamp('%Y-%m-%dT%H:%M:%S%z')).should_not =~ '2009-12-03 00:12:37+0100'
      anchored(timestamp('%Y-%m-%dT%H:%M:%S%z')).should_not =~ '2009-12-03T00:12:37'
    end
  end

  
  describe '.hostname' do
    it "should parse hostnames successfully" do
      anchored(hostname).should =~ 'railsdoctors.com'
      anchored(hostname).should =~ 'www.rails-doctors.com'
      anchored(hostname).should =~ 'hostname.co.uk'
      anchored(hostname).should =~ 'localhost'
    
      anchored(hostname).should_not =~ '192.168.0.1'
      anchored(hostname).should_not =~ '3ffe:1900:4545:3:200:f8ff:fe21:67cf'
      anchored(hostname).should_not =~ 'railsdoctors.'
    end
  end
  
  describe '.ip_address' do
    it "should parse IPv4 addresses" do
      anchored(ip_address).should =~ '127.0.0.1'
      anchored(ip_address).should =~ '255.255.255.255'
      
      anchored(ip_address).should_not =~ '2552.2552.2552.2552'
      anchored(ip_address).should_not =~ '127001'
      anchored(ip_address).should_not =~ ''
      anchored(ip_address).should_not =~ '-'
      anchored(ip_address).should_not =~ 'sub-host.domain.tld'
    end
    
    it "should pase IPv6 addresses" do
      anchored(ip_address).should =~ '::1'
      anchored(ip_address).should =~ '3ffe:1900:4545:3:200:f8ff:fe21:67cf'
      anchored(ip_address).should =~ '3ffe:1900:4545:3:200:f8ff:127.0.0.1'
      anchored(ip_address).should =~ '::3:200:f8ff:127.0.0.1'
      anchored(ip_address).should =~ '0:0:0:0:0:0:0:1'
      
      anchored(ip_address).should_not =~ 'qqqq:wwww:eeee:3q:200:wf8ff:fe21:67cf'
      anchored(ip_address).should_not =~ '3ffe44:1900f:454545:3:200:f8ff:ffff:5432'
    end
    
    it "should allow blank if true is given as parameter" do
      anchored(ip_address(true)).should =~ ''
      anchored(ip_address(true)).should_not =~ ' '
    end
    
    it "should allow a nil substitute if a string is given as parameter" do
      anchored(ip_address('-')).should =~ '-'
      anchored(ip_address('-')).should_not =~ ' -'
      anchored(ip_address('-')).should_not =~ '--'
      anchored(ip_address('-')).should_not =~ ''
    end
  end
  
  
  describe '.hostname_or_ip_address' do
    it "should parse either hostnames or ip addresses" do
      anchored(hostname_or_ip_address).should =~ 'railsdoctors.com'
      anchored(hostname_or_ip_address).should =~ 'hostname.co.uk'
      anchored(hostname_or_ip_address).should =~ 'localhost'
      anchored(hostname_or_ip_address).should =~ '192.168.0.1'
      anchored(hostname_or_ip_address).should =~ '3ffe:1900:4545:3:200:f8ff:fe21:67cf'
      
      anchored(hostname_or_ip_address).should_not =~ 'railsdoctors.'
    end
  end  
end

