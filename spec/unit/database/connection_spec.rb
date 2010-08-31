require 'spec_helper'

describe RequestLogAnalyzer::Database::Connection do
  describe '.from_string' do

    it "should parse a name-value based string" do
      string = 'adapter=sqlite3;database=filename.db'
      RequestLogAnalyzer::Database::Connection.from_string(string).should == {:adapter => 'sqlite3', :database => 'filename.db'}
    end

    it "should parse an URI-based string for SQLite3" do
      string = 'sqlite3://filename.db'
      RequestLogAnalyzer::Database::Connection.from_string(string).should == {:adapter => 'sqlite3', :database => 'filename.db'}
    end

    it "should parse an URI-based string for MySQL" do
      string = 'mysql://localhost.local/database'
      RequestLogAnalyzer::Database::Connection.from_string(string).should ==
              { :adapter => 'mysql', :database => 'database', :host => 'localhost.local' }
    end

    it "should parse an URI-based string for MySQL with only username" do
      string = 'mysql://username@localhost.local/database'
      RequestLogAnalyzer::Database::Connection.from_string(string).should ==
              { :adapter => 'mysql', :database => 'database', :host => 'localhost.local', :username => 'username' }
    end

    it "should parse an URI-based string for MySQL with username and password" do
      string = 'mysql://username:password@localhost.local/database'
      RequestLogAnalyzer::Database::Connection.from_string(string).should ==
              { :adapter => 'mysql', :database => 'database', :host => 'localhost.local', :username => 'username', :password => 'password' }
    end
  end
end
