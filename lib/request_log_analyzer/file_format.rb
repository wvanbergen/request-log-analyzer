module RequestLogAnalyzer::FileFormat

  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end

  # Loads a FileFormat::Base subclass instance.
  # You can provide:
  # * A FileFormat instance (which will return itself)
  # * A FileFormat class (of which an imstance will be returned)
  # * A filename (from which the FileFormat class is loaded)
  # * A symbol of a built-in file format (e.g. :rails)
  def self.load(file_format, *args)
    klass = nil
    if file_format.kind_of?(RequestLogAnalyzer::FileFormat::Base)
      # this already is a file format! return itself
      return @current_file_format = file_format

    elsif file_format.kind_of?(Class) && file_format.ancestors.include?(RequestLogAnalyzer::FileFormat::Base)
      # a usable class is provided. Use this format class.
      klass = file_format

    elsif file_format.kind_of?(String) && File.exist?(file_format)
      # load a format from a ruby file
      require file_format
      const = RequestLogAnalyzer::to_camelcase(File.basename(file_format, '.rb'))
      if RequestLogAnalyzer::FileFormat.const_defined?(const)
        klass = RequestLogAnalyzer::FileFormat.const_get(const)
      elsif Object.const_defined?(const)
        klass = Object.const_get(const)
      else
        raise "Cannot load class #{const} from #{file_format}!"
      end

    else
      # load a provided file format
      klass = RequestLogAnalyzer::FileFormat.const_get(RequestLogAnalyzer::to_camelcase(file_format))
    end

    # check the returned klass to see if it can be used
    raise "Could not load a file format from #{file_format.inspect}" if klass.nil?
    raise "Invalid FileFormat class from #{file_format.inspect}" unless klass.kind_of?(Class) && klass.ancestors.include?(RequestLogAnalyzer::FileFormat::Base)

    @current_file_format = klass.create(*args) # return an instance of the class
  end

  # Base class for all log file format definitions. This class provides functions for subclasses to
  # define their LineDefinitions and to define a summary report.
  #
  # A subclass of this class is instantiated when request-log-analyzer is started and this instance
  # is shared with all components of the application so they can act on the specifics of the format
  class Base

    attr_reader :line_definitions, :report_trackers

    ####################################################################################
    # CLASS METHODS for format definition
    ####################################################################################

    # Registers the line definer instance for a subclass.
    def self.inherited(subclass)
      if subclass.superclass == RequestLogAnalyzer::FileFormat::Base

        # Create aline and report definer for this class
        subclass.class_eval do
          instance_variable_set(:@line_definer, RequestLogAnalyzer::LineDefinition::Definer.new)
          instance_variable_set(:@report_definer, RequestLogAnalyzer::Aggregator::Summarizer::Definer.new)
          class << self; attr_accessor :line_definer, :report_definer; end
        end

        # Create a custom Request class for this file format
        subclass.const_set('Request', Class.new(RequestLogAnalyzer::Request)) unless subclass.const_defined?('Request')
      else

        # Copy the line and report definer from the parent class.
        subclass.class_eval do
          instance_variable_set(:@line_definer, superclass.line_definer.clone)
          instance_variable_set(:@report_definer, superclass.report_definer.clone)
          class << self; attr_accessor :line_definer, :report_definer; end
        end

        # Create a custom Request class based on the superclass's Request class
        subclass.const_set('Request', Class.new(subclass.superclass::Request)) unless subclass.const_defined?('Request')
      end
    end

    # Specifies a single line defintions.
    def self.line_definition(name, &block)
      @line_definer.send(name, &block)
    end

    # Specifies multiple line definitions at once using a block
    def self.format_definition(&block)
      if block_given?
        yield self.line_definer
      else
        return self.line_definer
      end
    end

    # Specifies the summary report using a block.
    def self.report(mode = :append, &block)
      self.report_definer.reset! if mode == :overwrite
      yield(self.report_definer)
    end

    ####################################################################################
    # Instantiation
    ####################################################################################

    def self.create(*args)
      # Ignore arguments
      return self.new(line_definer.line_definitions, report_definer.trackers)
    end

    def initialize(line_definitions = {}, report_trackers = [])
      @line_definitions, @report_trackers = line_definitions, report_trackers
    end

    ####################################################################################
    # INSTANCE methods
    ####################################################################################

    # Returns the Request class of this file format
    def request_class
      self.class::Request
    end

    # Returns a Request instance with the given parsed lines that should be provided as hashes.
    def request(*hashes)
      request_class.create(self, *hashes)
    end

    # Checks whether the line definitions form a valid language.
    # A file format should have at least a header and a footer line type
    def valid?
      line_definitions.any? { |(name, ld)| ld.header } && line_definitions.any? { |(name, ld)| ld.footer }
    end

    # Returns true if this language captures the given symbol in one of its line definitions
    def captures?(name)
      line_definitions.any? { |(name, ld)| ld.captures?(name) }
    end

    # Function that a file format con implement to monkey patch the environment.
    # * <tt>controller</tt> The environment is provided as a controller instance
    def setup_environment(controller)
    end

    # Parses a line by trying to parse it using every line definition in this file format
    def parse_line(line, &warning_handler)
      self.line_definitions.each do |lt, definition|
        match = definition.matches(line, &warning_handler)
        return match if match
      end

      return nil
    end
  end
end