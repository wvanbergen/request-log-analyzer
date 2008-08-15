module CommandLine
  
  class Flag
    
    attr_reader :name
    attr_reader :alias
    attr_reader :argument
    
    def initialize(name, definition)
      @name     = name.to_s.gsub(/_/, '-').to_sym
      @alias    = definition[:alias].to_sym if definition[:alias]
      @required = definition.has_key?(:required) && definition[:required] == true
      @argument = definition[:expects] if definition[:expects]
    end
    
    def to_argument
      "--#{@name}"
    end
    
    def to_alias
      "-#{@alias}"
    end
        
    def has_alias?
      !@alias.nil?
    end
    
    def optional?
      !@required
    end
    
    def required?
      @required
    end
    
    def expects_argument?
      !@argument.nil?
    end
  end  
  
end