module CommandLine
  
  # Argument flag handling.
  class Flag
    
    attr_reader :name
    attr_reader :alias
    attr_reader :argument
    attr_reader :default
    attr_reader :multiple
    
    # Initialize new Flag
    # <tt>name</tt> The name of the flag
    # <tt>definition</tt> The definition of the flag.
    def initialize(name, definition)
      @name     = name.to_s.gsub(/_/, '-').to_sym
      @alias    = definition[:alias].to_sym if definition[:alias]
      @required = definition.has_key?(:required) && definition[:required] == true
      @argument = definition[:expects] if definition[:expects]
      @multiple = definition[:multiple] || false
      @default  = definition[:default] if definition[:default]
    end
    
    # Argument representation of the flag (--fast)
    def to_argument
      "--#{@name}"
    end
    
    # Argument alias representation of the flag (-f)
    def to_alias
      "-#{@alias}"
    end
        
    # Check if flag has an alias
    def has_alias?
      !@alias.nil?
    end
    
    # Check if flag is optional
    def optional?
      !@required
    end
    
    def multiple?
      @multiple
    end
    
    def default?
      !@default.nil?
    end
    
    # Check if flag is required
    def required?
      @required
    end
    
    # Check if flag expects an argument (Are you talking to me?)
    def expects_argument?
      !@argument.nil?
    end
  end  
  
end