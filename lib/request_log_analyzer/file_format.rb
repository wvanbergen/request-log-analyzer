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
  def self.load(file_format)
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
      klass = Object.const_get(RequestLogAnalyzer::to_camelcase(File.basename(file_format, '.rb')))

    else
      # load a provided file format
      klass = RequestLogAnalyzer::FileFormat.const_get(RequestLogAnalyzer::to_camelcase(file_format))      
    end
    
    raise if klass.nil?
    @current_file_format = klass.new # return an instance of the class
  end  
  
  # Makes classes aware of a file format by registering the file_format variable
  module Awareness
    
    def self.included(base)
      base.send(:attr_reader, :file_format)
    end
    
    def register_file_format(format)
      @file_format = format
    end
  end  

  # Base class for all log file format definitions. This class provides functions for subclasses to 
  # define their LineDefinitions and to define a summary report.
  #
  # A subclass of this class is instantiated when request-log-analyzer is started and this instance
  # is shared with all components of the application so they can act on the specifics of the format
  class Base
      
    # Registers the line definer instance for a subclass.
    def self.inherited(subclass)
       subclass.instance_variable_set(:@line_definer, RequestLogAnalyzer::LineDefinition::Definer.new)
       subclass.class_eval { class << self; attr_accessor :line_definer; end } 
       subclass.class_eval { class << self; attr_accessor :report_definer; end }
       
       unless subclass.const_defined?('Request')
         subclass.const_set('Request', Class.new(RequestLogAnalyzer::Request))         
       end
    end    
    
    # Specifies a single line defintions.
    def self.line_definition(name, &block)
      @line_definer.send(name, &block)
    end
    
    def create_request(*hashes)
      self.class.const_get('Request').create(self, *hashes)
    end
    
    # Specifies multiple line definitions at once using a block
    def self.format_definition(&block)
      if block_given?
        yield(@line_definer) 
      else
        return @line_definer
      end
    end
    
    # Specifies the summary report using a block.
    def self.report(&block)
      @report_definer = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      yield(@report_definer)
    end

    # Returns all line definitions
    def line_definitions
      @line_definitions ||= self.class.line_definer.line_definitions
    end
    
    # Returns all the defined trackers for the summary report.
    def report_trackers
      self.class.instance_variable_get(:@report_definer).trackers rescue []
    end
    
    # Checks whether the line definitions form a valid language.
    # A file format should have at least a header and a footer line type
    def valid?
      line_definitions.detect { |(name, ld)| ld.header } && line_definitions.detect { |(name, ld)| ld.footer }
    end
    
    # Function that a file format con implement to monkey patch the environment.
    # * <tt>controller</tt> The environment is provided as a controller instance
    def setup_environment(controller)
      
    end
  end
end