require "#{File.dirname(__FILE__)}/flag"
require "#{File.dirname(__FILE__)}/exceptions"

# Module used to parse commandline arguments
module CommandLine
  
  # Parse argument lists and return an argument object containing all set flags and switches.
  class Arguments
    
    FLAG_REGEXP = /^--?[A-z0-9]/
    
    attr_reader :flag_definitions
    
    attr_reader :flags
    attr_reader :files
    attr_reader :command
    
    attr_accessor :required_files
    
    # Initializer.
    # <tt>arguments</tt> The arguments which are going to be parsed (defaults to $*).
    def initialize(arguments = $*, &block)
      @arguments = arguments
      @flag_definitions = {}
      @begins_with_command = false
    end
    
    # Parse a list of arguments. Intatiates a Argument object with the given arguments and yeilds
    # it so that flags and switches can be set by the application.
    # <tt>arguments</tt> The arguments which are going to be parsed (defaults to $*).
    # Returns the arguments object.parse!
    def self.parse(arguments = $*, &block)
      cla = Arguments.new(arguments)
      yield(cla)
      return cla.parse!
    end
    
    # Handle argument switches for the application
    # <tt>switch</tt> A switch symbol like :fast
    # <tt>switch_alias</tt> An short alias for the same switch (:f).
    def switch(switch, switch_alias = nil)
      return self.flag(switch, :alias => switch_alias, :expects => nil)
    end
    
    # Handle argument flags for the application
    # <tt>flag</tt> A flag symbol like :fast
    # Options
    # * <tt>:expects</tt> Expects a value after the flag
    def flag(flag, options = {})
      options[:expects] = String unless options.has_key?(:expects)
      argument = Flag.new(flag, options)
      @flag_definitions[argument.to_argument]  = argument
      @flag_definitions[argument.to_alias]     = argument if argument.has_alias?
      return argument
    end
    
    # If called argument list must begin with a command.
    # <tt>begins_w_command</tt> Defaults to true.
    def begins_with_command!(begins_w_command=true)
      @begins_with_command = begins_w_command
    end
    
    # Unknown flags will be silently ignored.
    # <tt>ignore</tt> Defaults to true.
    def ignore_unknown_flags!(ignore = true)
      @ignore_unknown_flags = ignore
    end
  
    def [](name)
      return flags[name.to_s.gsub(/_/, '-').to_sym]
    end
  
    # Parse the flags and switches set by the application.
    # Returns an arguments object containing the flags and switches found in the commandline.
    def parse!
      @flags = {}
      @files = []
      
      i = 0
      while @arguments.length > i do
        arg = @arguments[i]
        if FLAG_REGEXP =~ arg
          if @flag_definitions.has_key?(arg)
            flag = @flag_definitions[arg]
            if flag.expects_argument?
              
              if @arguments.length > (i + 1) && @arguments[i + 1]
                
                if flag.multiple?
                  @flags[flag.name] ||= []
                  @flags[flag.name] << @arguments[i + 1]
                else
                  @flags[flag.name] = @arguments[i + 1]
                end
                                
                i += 1
              else
                raise CommandLine::FlagExpectsArgument.new(arg)
              end              
              
            else
              @flags[flag.name] = true
            end
          else
            raise CommandLine::UnknownFlag.new(arg) unless @ignore_unknown_flags
          end
        else
          if @begins_with_command && @command.nil?
            @command = arg
          else
            @files << arg
          end
        end
        i += 1        
      end
      
      check_parsed_arguments!
      
      return self
    end
    
    # Check if the parsed arguments meet their requirements.
    # Raises CommandLineexception on error.
    def check_parsed_arguments!
      
      @flag_definitions.each do |flag, definition| 
        @flags[definition.name] ||= [] if definition.multiple? && !definition.default?
        @flags[definition.name] ||= definition.default if definition.default?
      end

      if @begins_with_command && @command.nil? 
        raise CommandLine::CommandMissing.new
      end

      if @required_files && @files.length < @required_files
        raise CommandLine::FileMissing.new("You need at least #{@required_files} files")
      end

    end
  end

end