require "#{File.dirname(__FILE__)}/flag"
require "#{File.dirname(__FILE__)}/exceptions"

module CommandLine
  
  class Arguments
    
    FLAG_REGEXP = /^--?[A-z0-9]/
    
    attr_reader :flag_definitions
    
    attr_reader :flags
    attr_reader :files
    attr_reader :command
    
    attr_accessor :required_files
    
    def initialize(arguments = $*, &block)
      @arguments = arguments
      @flag_definitions = {}
      @begins_with_command = false
    end

    def self.parse(arguments = $*, &block)
      cla = Arguments.new(arguments)
      yield(cla)
      return cla.parse!
    end
    
    def switch(flag, flag_alias = nil)
      return self.flag(flag, :alias => flag_alias, :expects => nil)
    end
    
    def flag(flag, options) 
      options[:expects] = String unless options.has_key?(:expects)
      argument = Flag.new(flag, options)
      @flag_definitions[argument.to_argument]  = argument
      @flag_definitions[argument.to_alias]     = argument if argument.has_alias?
      return argument
    end
    
    def begins_with_command!
      @begins_with_command = true
    end
    
    def ignore_unknown_flags!
      @ignore_unknown_flags = true
    end    
  
    def [](name)
      return flags[name.to_s.gsub(/_/, '-').to_sym]
    end
  
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
                @flags[flag.name] = @arguments[i + 1]
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
    
    def check_parsed_arguments!
      if @begins_with_command && @command.nil? 
        raise CommandLine::CommandMissing.new
      end
      if !@required_files.nil? && @files.length < @required_files
        raise CommandLine::FileMissing.new("You need at least #{@required_files} files")
      end
    end

  end

end