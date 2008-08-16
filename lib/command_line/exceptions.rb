module CommandLine
  
  # Commandline parsing errors and exceptions
  class Error < Exception
  end

  # Missing a required flag
  class FlagMissing < CommandLine::Error
  end

  # Missing a required file
  class FileMissing < CommandLine::Error
  end

  # Missing a required flag argument
  class FlagExpectsArgument < CommandLine::Error
    def initialize(flag)
      super("#{flag} expects an argument!")
    end    
  end

  # Missing a required command
  class CommandMissing < CommandLine::Error
    def initialize(msg = "A command is missing")
      super(msg)
    end
    
  end

  # Encountered an unkown flag
  class UnknownFlag < CommandLine::Error
    def initialize(flag)
      super("#{flag} not recognized as a valid flag!")
    end
  end
  
end