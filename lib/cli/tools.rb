module CommandLine
  module Tools
    extend self

    # Try to determine the terminal with.
    # If it is not possible to to so, it returns the default_width.
    # <tt>default_width</tt> Defaults to 81
    def terminal_width(default_width = 81, out = STDOUT)

      begin
        tiocgwinsz = 0x5413
        data = [0, 0, 0, 0].pack("SSSS")
        if !RUBY_PLATFORM.include?('java') && out.ioctl(tiocgwinsz, data) >= 0 # JRuby crashes on ioctl
          _, cols, _, _ = data.unpack("SSSS")
          raise unless cols > 0
          cols
        else
          raise
        end
      rescue
        begin
          IO.popen('stty -a 2>&1') do |pipe|
            column_line = pipe.detect { |line| /(\d+) columns/ =~ line }
            raise unless column_line
            $1.to_i
          end
        rescue
          default_width
        end
      end
    end

    # Copies request-log-analyzer analyzer rake tasks into the /lib/tasks folder of a project, for easy access and
    # environment integration.
    # <tt>install_type</tt> Type of project to install into. Defaults to :rails.
    # Raises if it cannot find the project folder or if the install_type is now known.
    def install_rake_tasks(install_type = :rails)
      if install_type.to_sym == :rails
        require 'fileutils'
        if File.directory?('./lib/tasks/')
          task_file = File.expand_path('../../tasks/request_log_analyzer.rake', File.dirname(__FILE__))
          FileUtils.copy(task_file, './lib/tasks/request_log_analyze.rake')
          puts "Installed rake tasks."
          puts "To use, run: rake rla:report"
        else
          puts "Cannot find /lib/tasks folder. Are you in your Rails directory?"
          puts "Installation aborted."
        end
      else
        raise "Cannot perform this install type! (#{install_type.to_s})"
      end
    end
  end
end
