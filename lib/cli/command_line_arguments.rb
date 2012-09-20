module CommandLine

  class Option

    attr_reader :name, :alias
    attr_reader :parameter_count
    attr_reader :default_value

    # Rewrites a command line keyword by replacing the underscores with dashes
    # <tt>sym</tt> The symbol to rewrite
    def self.rewrite(sym)
      sym.to_s.gsub(/_/, '-').to_sym
    end

    # Initialize new CommandLine::Option
    # <tt>name</tt> The name of the flag
    # <tt>definition</tt> The definition of the flag.
    def initialize(name, definition = {})
      @name            = CommandLine::Option.rewrite(name)
      @alias           = definition[:alias] ? definition[:alias].to_sym : nil
      @required        = definition.has_key?(:required) && definition[:required] == true
      @parameter_count = definition[:parameters] || 1
      @multiple        = definition[:multiple]   || false
      @default_value   = definition[:default]    || false
    end

    def parse(arguments_parser)
      if @parameter_count == 0
        return true
      elsif @parameter_count == 1
        parameter = arguments_parser.next_parameter
        raise CommandLine::ParameterExpected, self if parameter.nil?
        return parameter
      elsif @parameter_count == :any
        parameters = []
        while parameter = arguments_parser.next_parameter && parameter != '--'
          parameters << parameter
        end
        return parameters
      else
        parameters = []
        @parameter_count.times do |n|
          parameter = arguments_parser.next_parameter
          raise CommandLine::ParameterExpected, self if parameter.nil?
          parameters << parameter
        end
        return parameters
      end
    end

    def =~(test)
      [@name, @alias].include?(CommandLine::Option.rewrite(test))
    end

    # Argument representation of the flag (--fast)
    def to_option
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

    # Check if flag is required
    def required?
      @required
    end

    # Check if flag is optional
    def optional?
      !@required
    end

    def multiple?
      @multiple
    end

    def has_default?
      !@default_value.nil?
    end
  end

  class Arguments

    class Definition

      ENDLESS_PARAMETERS = 99999

      attr_reader :commands, :options, :parameters

      def initialize(parent)
        @parent = parent
        @options  = {}
        @commands = {}
        @parameters = nil
      end

      def [](option_name)
        option_symbol = CommandLine::Option.rewrite(option_name)
        if the_option = @options.detect { |(_, odef)| odef =~ option_symbol }
          the_option[1]
        else
          raise CommandLine::UnknownOption, option_name
        end
      end

      def minimum_parameters=(count_specifier)
        @parameters = count_specifier..ENDLESS_PARAMETERS
      end

      def parameters=(count_specifier)
        @parameters = count_specifier
      end

      alias :files= :parameters=

      def option(name, options = {})
        clo = CommandLine::Option.new(name, options)
        @options[clo.name] = clo
      end

      def switch(name, switch_alias = nil)
        option(name, :alias => switch_alias, :parameters => 0)
      end

      def command(name, &block)
        command_definition = Definition.new(self)
        yield(command_definition) if block_given?
        @commands[CommandLine::Option.rewrite(name)] = command_definition
      end

      def has_command?(command)
        @commands[CommandLine::Option.rewrite(command)]
      end
    end

    OPTION_REGEXP  = /^\-\-([A-Za-z0-9-]+)$/;
    ALIASES_REGEXP = /^\-([A-Aa-z0-9]+)$/

    attr_reader :definition
    attr_reader :tokens
    attr_reader :command, :options, :parameters

    def self.parse(tokens = $*, &block)
      cla = Arguments.new
      cla.define(&block)
      return cla.parse!(tokens)
    end

    def initialize
      @tokens = []
      @definition = Definition.new(self)
      @current_definition = @definition
    end

    def define(&block)
      yield(@definition)
    end

    def [](option)
      if the_option = @options.detect { |(key, _)| key =~ option }
        the_option[1]
      else
        @current_definition[option].default_value
      end
    end

    def next_token
      @current_token = @tokens.shift
      return @current_token
    end

    def next_parameter
      parameter_candidate = @tokens.first
      parameter = (parameter_candidate.nil? || OPTION_REGEXP =~ parameter_candidate || ALIASES_REGEXP =~ parameter_candidate) ? nil : @tokens.shift
      return parameter
    end

    def parse!(tokens)
      @current_definition = @definition
      @first_token = true
      @tokens      = tokens.clone

      @options = {}
      @parameters   = []
      @command = nil

      prepare_result!

      while next_token

        if @first_token && command_definition = @definition.has_command?(@current_token)
          @current_definition = command_definition
          @command = CommandLine::Option.rewrite(@current_token)
        else
          case @current_token
            when ALIASES_REGEXP; handle_alias_expansion($1)
            when OPTION_REGEXP;  handle_option($1)
            else;                handle_other_parameter(@current_token)
          end
          @first_token = false
        end

      end

      validate_arguments!

      return self
    end

    protected

    def prepare_result!
      multiple_options = Hash[*@current_definition.options.select { |name, o| o.multiple? }.flatten]
      multiple_options.each { |name, definition| @options[definition] = [] }
    end

    def validate_arguments!
      if @current_definition.parameters && !(@current_definition.parameters === @parameters.length)
        raise CommandLine::ParametersOutOfRange.new(@current_definition.parameters, @parameters.length)
      end

      required_options = Hash[*@current_definition.options.select { |name, o| o.required? }.flatten]
      required_options.each do |name, definition|
        raise CommandLine::RequiredOptionMissing, definition unless self[name]
      end
    end

    def handle_alias_expansion(aliases)
      aliases.reverse.scan(/./) do |alias_char|
        if option_definition = @current_definition[alias_char]
          @tokens.unshift(option_definition.to_option)
        else
          raise CommandLine::UnknownOption, alias_char
        end
      end
    end

    def handle_other_parameter(parameter)
      @parameters << parameter
    end

    def handle_option(option_name)
      option_definition = @current_definition[option_name]
      raise CommandLine::UnknownOption, option_name if option_definition.nil?

      if option_definition.multiple?
        @options[option_definition] << option_definition.parse(self)
      else
        @options[option_definition] = option_definition.parse(self)
      end
    end

  end

  # Commandline parsing errors and exceptions
  class Error < Exception
  end

  # Missing a required flag
  class RequiredOptionMissing < CommandLine::Error
    def initialize(option)
      super("You have to provide the #{option.name} option!")
    end
  end

  # Missing a required file
  class ParametersOutOfRange < CommandLine::Error
    def initialize(expected, actual)
      if expected.kind_of?(Range)
        if expected.end == CommandLine::Arguments::Definition::ENDLESS_PARAMETERS
          super("The command expected at least #{expected.begin} parameters, but found #{actual}!")
        else
          super("The command expected between #{expected.begin} and #{expected.end} parameters, but found #{actual}!")
        end
      else
        super("The command expected #{expected} parameters, but found #{actual}!")
      end
    end
  end

  # Missing a required flag argument
  class ParameterExpected < CommandLine::Error
    def initialize(option)
      super("The option #{option.inspect} expects a parameter!")
    end
  end

  # Encountered an unkown flag
  class UnknownOption < CommandLine::Error
    def initialize(option_identifier)
      super("#{option_identifier.inspect} not recognized as a valid option!")
    end
  end
end