# Degrate gracefully if mailtrap is missing
begin
  require 'mailtrap'
  require File.dirname(__FILE__) + '/../spec_helper.rb'

  describe RequestLogAnalyzer, 'running as a mailer' do

    before(:each) do
      cleanup_temp_files!
      @log_file = temp_output_file('mailtrap.log')
    
      `mailtrap start --once --file #{@log_file}`
    end

    after(:each) do
      `mailtrap stop`
      cleanup_temp_files!
    end

    it "should send plaintext mail" do
      RequestLogAnalyzer::Controller.build(
        :mail         => 'root@localhost',
        :mailhost     => 'localhost:2525',
        :source_files => log_fixture(:rails_1x),
        :format       => RequestLogAnalyzer::FileFormat::Rails,
        :no_progress  => true
      ).run!

      sleep(1) # Allow mailtrap to write to log file
      find_string_in_file("From: <contact@railsdoctors.com>", @log_file).should_not be_nil
      find_string_in_file("To: <root@localhost>", @log_file).should_not be_nil
      find_string_in_file("From: Request-log-analyzer reporter <contact@railsdoctors.com>", @log_file).should_not be_nil
      find_string_in_file("Request summary", @log_file).should_not be_nil
      find_string_in_file("PeopleController#show.html [ |    1 |  0.29s |  0.29s |  0.00s |  0.29s |  0.29s", @log_file).should_not be_nil
    end

    it "should send html mail" do
      RequestLogAnalyzer::Controller.build(
        :output       => 'HTML',
        :mail         => 'root@localhost',
        :mailhost     => 'localhost:2525',
        :source_files => log_fixture(:rails_1x),
        :format       => RequestLogAnalyzer::FileFormat::Rails,
        :no_progress  => true
      ).run!
    
      sleep(1) # Allow mailtrap to write to log file    
      find_string_in_file("From: <contact@railsdoctors.com>", @log_file).should_not be_nil
      find_string_in_file("To: <root@localhost>", @log_file).should_not be_nil
      find_string_in_file("From: Request-log-analyzer reporter <contact@railsdoctors.com>", @log_file).should_not be_nil
      find_string_in_file('<h1>Request-log-analyzer summary report</h1>', @log_file).should_not be_nil
      find_string_in_file('<td class="alt">0.29s</td></tr><tr><td>DashboardController#index.html [GET]</td>', @log_file).should_not be_nil
    end
  end

rescue LoadError => e
  $stderr.puts "\nSkipping mailer_spec tests. `gem install mailtrap` and try again.\n\n"
end

