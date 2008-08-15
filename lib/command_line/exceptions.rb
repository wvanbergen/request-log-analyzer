module CommandLine
  
  class Error < Exception
  end
  
  class FlagMissing < CommandLine::Error
  end

  class FileMissing < CommandLine::Error
  end

  class FlagExpectsArgument < CommandLine::Error
    def initialize(flag)
      super("#{flag} expects an argument!")
    end    
  end

  class CommandMissing < CommandLine::Error
    def initialize(msg = "A command is missing")
      super(msg)
    end
    
  end

  class UnknownFlag < CommandLine::Error
    def initialize(flag)
      super("#{flag} not recognized as a valid flag!")
    end
  end
  
end