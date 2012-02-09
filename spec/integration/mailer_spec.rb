require 'spec_helper'
require 'socket'

unless defined?(JRUBY_VERSION) #No Fork on JRUBY

describe RequestLogAnalyzer, 'running mailer integration' do

  before(:each) do
    @log_file = temp_output_file('mailtrap.log')

    Process.fork {
      Mailtrap.new('localhost', 2525, true, @log_file)
      Process.exit! # Do not call rspec after exit hook!
    }
  end

  after(:each) do
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
    
    Process.wait # Wait for mailer to complete

    find_string_in_file("From: <contact@railsdoctors.com>", @log_file).should_not be_nil
    find_string_in_file("To: <root@localhost>", @log_file).should_not be_nil
    find_string_in_file("From: Request-log-analyzer reporter <contact@railsdoctors.com>", @log_file).should_not be_nil
    find_string_in_file("Subject: Request log analyzer report - generated on", @log_file).should_not be_nil
    find_string_in_file("Request summary", @log_file).should_not be_nil
    find_string_in_file("PeopleControll |    1 |  0.04s |  0.04s |  0.00s |  0.04s |  0.04s | 0.04s-0.04s", @log_file).should_not be_nil
  end
  
  it "should allow a custom mail subject" do
    RequestLogAnalyzer::Controller.build(
      :mail         => 'root@localhost',
      :mailhost     => 'localhost:2525',
      :mailsubject  => 'TESTSUBJECT',
      :source_files => log_fixture(:rails_1x),
      :format       => RequestLogAnalyzer::FileFormat::Rails,
      :no_progress  => true
    ).run!
    
    Process.wait # Wait for mailer to complete

    find_string_in_file("Subject: TESTSUBJECT", @log_file).should_not be_nil  
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
  
    Process.wait # Wait for mailer to complete

    find_string_in_file("From: <contact@railsdoctors.com>", @log_file).should_not be_nil
    find_string_in_file("To: <root@localhost>", @log_file).should_not be_nil
    find_string_in_file("From: Request-log-analyzer reporter <contact@railsdoctors.com>", @log_file).should_not be_nil
    find_string_in_file('<h1>Request-log-analyzer summary report</h1>', @log_file).should_not be_nil
    find_string_in_file('<td class="alt">0.29s-0.30s</td></tr><tr><td>DashboardController#index.html [GET]</td>', @log_file).should_not be_nil
  end
end



# Mailtrap
#     by Matt Mower <self@mattmower.com>
#     http://matt.blogs.it/
#
# Included in RLA because original mailtrap puts anoying stuff when called
# through ruby.
# 
# Mailtrap creates a TCP server that listens on a specified port for SMTP
# clients. Accepts the connection and talks just enough of the SMTP protocol
# for them to deliver a message which it writes to disk.
#
class Mailtrap
  VERSION = '0.2.1'

  # Create a new Mailtrap on the specified host:port. If once it true it
  # will listen for one message then exit. Specify the msgdir where messages
  # are written.
  def initialize( host, port, once, msgfile )
    @host = host
    @port = port
    @once = once
    @msgfile = msgfile
    
    File.open( @msgfile, "a" ) do |file|
      file.puts "\n* Mailtrap started at #{@host}:#{port}\n"
    end

    service = TCPServer.new( @host, @port )
    accept( service )
  end

  # Service one or more SMTP client connections
  def accept( service )
    while session = service.accept

      class << session
        def get_line
          line = gets
          line.chomp! unless line.nil?
          line          
        end
      end

      begin
        serve( session )
      rescue Exception => e
      end

      break if @once
    end    
  end

  # Write a plain text dump of the incoming email to a text
  # file. The file will be in the @msgdir folder and will
  # be called smtp0001.msg, smtp0002.msg, and so on.
  def write( from, to_list, message )

    # Strip SMTP commands from To: and From:
    from.gsub!( /MAIL FROM:\s*/, "" )
    to_list = to_list.map { |to| to.gsub( /RCPT TO:\s*/, "" ) }

    # Append to the end of the messages file
    File.open( @msgfile, "a" ) do |file|
      file.puts "* Message begins"
      file.puts "From: #{from}"
      file.puts "To: #{to_list.join(", ")}"
      file.puts "Body:"
      file.puts message
      file.puts "\n* Message ends"
    end

  end

  # Talk pidgeon-SMTP to the client to get them to hand over the message
  # and go away.
  def serve( connection )
    connection.puts( "220 #{@host} MailTrap ready ESTMP" )
    helo = connection.get_line # whoever they are

    if helo =~ /^EHLO\s+/
      connection.puts "250-#{@host} offers just ONE extension my pretty"
      connection.puts "250 HELP"
    end

    # Accept MAIL FROM:
    from = connection.get_line
    connection.puts( "250 OK" )

    to_list = []

    # Accept RCPT TO: until we see DATA
    loop do
      to = connection.get_line
      break if to.nil?

      if to =~ /^DATA/
        connection.puts( "354 Start your message" )
        break
      else
        to_list << to
        connection.puts( "250 OK" )
      end
    end

    # Capture the message body terminated by <CR>.<CR>
    lines = []
    loop do
      line = connection.get_line
      break if line.nil? || line == "."
      lines << line
    end

    # We expect the client will go away now
    connection.puts( "250 OK" )
    connection.gets # Quit
    connection.puts "221 Seeya"
    connection.close

    write( from, to_list, lines.join( "\n" ) )
  end
end

else
  p 'Skipping mailer integration specs, because of missing Process.fork()'
end