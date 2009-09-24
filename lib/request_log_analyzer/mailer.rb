module RequestLogAnalyzer

  class Mailer

    attr_accessor :data, :to, :host

    # Initialize a mailer
    # <tt>to</tt> to address
    # <tt>host</tt> the mailer host
    # <tt>options</tt> Specific style options
    # Options
    # <tt>:debug</tt> Do not actually mail
    def initialize(to, host = 'localhost', options = {})
      require 'net/smtp'
      @to      = to
      @host    = host
      @options = options
      @data    = []
    end

    def mail
      from        = @options[:from]        || 'contact@railsdoctors.com'
      from_alias  = @options[:from_alias]  || 'Request-log-analyzer reporter'
      to_alias    = @options[:to_alias]    || to
      subject     = @options[:subjeect]    || "Request log analyzer report - generated on #{Time.now.to_s}"
    msg = <<END_OF_MESSAGE
From: #{from_alias} <#{from}>
To: #{to_alias} <#{@to}>
Subject: #{subject}

#{@data.to_s}
END_OF_MESSAGE
    
      unless @options[:debug]
        Net::SMTP.start(@host) do |smtp|
          smtp.send_message msg, from, to
        end
      end

      return [msg, from, to] 
    end

    def << string
      data << string
    end

    def puts string
      data << string
    end

  end
end