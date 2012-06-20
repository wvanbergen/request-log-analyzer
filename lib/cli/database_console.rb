class DatabaseConsole

  IRB = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'

  def initialize(arguments)
    @arguments = arguments
  end

  def run!
    libraries = ['irb/completion', 'rubygems','cli/database_console_init']
    libaries_string = libraries.map { |l| "-r #{l}" }.join(' ')

    ENV['RLA_DBCONSOLE_DATABASE'] = @arguments[:database]
    if @arguments[:apache_format]
      ENV['RLA_DBCONSOLE_FORMAT'] = 'apache'
      ENV['RLA_DBCONSOLE_FORMAT_ARGUMENT'] = @arguments[:apache_format]
    else
      ENV['RLA_DBCONSOLE_FORMAT'] = @arguments[:format]
    end
    # ENV['RLA_DBCONSOLE_FORMAT_ARGS'] = arguments['database']

    exec("#{IRB} #{libaries_string} --simple-prompt")
  end
end

