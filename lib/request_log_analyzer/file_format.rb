module RequestLogAnalyzer::FileFormat

  autoload :Rails,            'request_log_analyzer/file_format/rails'
  autoload :Rails3,           'request_log_analyzer/file_format/rails3'
  autoload :RailsDevelopment, 'request_log_analyzer/file_format/rails_development'
  autoload :Oink,             'request_log_analyzer/file_format/oink'
  autoload :Rack,             'request_log_analyzer/file_format/rack'
  autoload :Merb,             'request_log_analyzer/file_format/merb'
  autoload :Mysql,            'request_log_analyzer/file_format/mysql'
  autoload :Nginx,            'request_log_analyzer/file_format/nginx'
  autoload :Postgresql,       'request_log_analyzer/file_format/postgresql'
  autoload :DelayedJob,       'request_log_analyzer/file_format/delayed_job'
  autoload :DelayedJob2,      'request_log_analyzer/file_format/delayed_job2'
  autoload :DelayedJob21,     'request_log_analyzer/file_format/delayed_job21'
  autoload :DelayedJob3,      'request_log_analyzer/file_format/delayed_job3'
  autoload :Apache,           'request_log_analyzer/file_format/apache'
  autoload :AmazonS3,         'request_log_analyzer/file_format/amazon_s3'
  autoload :W3c,              'request_log_analyzer/file_format/w3c'
  autoload :Haproxy,          'request_log_analyzer/file_format/haproxy'

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

    elsif file_format.kind_of?(String) && File.exist?(file_format) && File.file?(file_format)
      # load a format from a ruby file
      require File.expand_path(file_format)

      const = RequestLogAnalyzer.to_camelcase(File.basename(file_format, '.rb'))
      if RequestLogAnalyzer::FileFormat.const_defined?(const)
        klass = RequestLogAnalyzer::FileFormat.const_get(const)
      elsif Object.const_defined?(const)
        klass = Object.const_get(const)
      else
        raise "Cannot load class #{const} from #{file_format}!"
      end

    else
      # load a provided file format
      klass = RequestLogAnalyzer::FileFormat.const_get(RequestLogAnalyzer.to_camelcase(file_format))
    end

    # check the returned klass to see if it can be used
    raise "Could not load a file format from #{file_format.inspect}" if klass.nil?
    raise "Invalid FileFormat class from #{file_format.inspect}" unless klass.kind_of?(Class) && klass.ancestors.include?(RequestLogAnalyzer::FileFormat::Base)

    @current_file_format = klass.create(*args) # return an instance of the class
  end
  
  # Returns an array of all FileFormat instances that are shipped with request-log-analyzer by default.
  def self.all_formats
    @all_formats ||= Dir[File.expand_path('file_format/*.rb', File.dirname(__FILE__))].map do |file| 
      self.load(File.basename(file, '.rb')) 
    end
  end
  
  # Autodetects the filetype of a given file.
  #
  # Returns a FileFormat instance, by parsing the first couple of lines of the provided file
  # with avery known file format and return the most promosing file format based on the parser
  # statistics. The <tt>autodetect_score</tt> method is used to score the fitness of a format.
  #
  # <tt>file</tt>:: The file to detect the file format for.
  # <tt>line_count</tt>:: The number of lines to take into consideration
  def self.autodetect(file, line_count = 50)
    
    parsers = all_formats.map { |f| RequestLogAnalyzer::Source::LogParser.new(f, :parse_strategy => 'cautious') }
    
    File.open(file, 'rb') do |io|
      while io.lineno < line_count && (line = io.gets)
        parsers.each { |parser| parser.parse_line(line) } 
      end
    end
    
    parsers.select { |p| autodetect_score(p) > 0 }.max { |a, b| autodetect_score(a) <=> autodetect_score(b) }.file_format rescue nil
  end
  
  # Calculates a file format auto detection score based on the parser statistics.
  #
  # This method returns a score as an integer. Usually, the score will increase as more
  # lines are parsed. Usually, a file_format with a score of zero or lower should not be
  # considered.
  #
  # <tt>parser</tt>:: The parsed that was use to parse the initial lines of the log file.
  def self.autodetect_score(parser)
    score  = 0
    score -= parser.file_format.line_definitions.length
    score -= parser.warnings * 3
    score += parser.parsed_lines * 1
    score += parser.parsed_requests * 10

    # As Apache matches several simular formats, subtracting 1 will make a specific matcher have a higher score
    score -= 1 if parser.file_format.class == RequestLogAnalyzer::FileFormat::Apache

    score
  end

  # This module contains some methods to construct regular expressions for log fragments
  # that are commonly used, like IP addresses and timestamp.
  #
  # You need to extend (or include in an unlikely case) this module in your file format 
  # to use these regular expression constructors.
  module CommonRegularExpressions

    TIMESTAMP_PARTS = {
      'a' => '(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)',
      'b' => '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)',
      'y' => '\d{2}', 'Y' => '\d{4}', 'm' => '\d{2}', 'd' => '\d{2}',
      'H' => '\d{2}', 'M' => '\d{2}', 'S' => '\d{2}', 'k' => '(?:\d| )\d',
      'z' => '(?:[+-]\d{4}|[A-Z]{3,4})',
      'Z' => '(?:[+-]\d{4}|[A-Z]{3,4})',
      '%' => '%'
    }
    
    # Creates a regular expression to match a hostname
    def hostname(blank = false)
      regexp = /(?:(?:[a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*(?:[A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])/
      add_blank_option(regexp, blank)
    end
    
    # Creates a regular expression to match a hostname or ip address
    def hostname_or_ip_address(blank = false)
      regexp = Regexp.union(hostname, ip_address)
      add_blank_option(regexp, blank)
    end

    # Create a regular expression for a timestamp, generated by a strftime call.
    # Provide the format string to construct a matching regular expression.
    # Set blank to true to allow and empty string, or set blank to a string to set
    # a substitute for the nil value.
    def timestamp(format_string, blank = false)
      regexp = ''
      format_string.scan(/([^%]*)(?:%([A-Za-z%]))?/) do |literal, variable|
        regexp << Regexp.quote(literal)
        if variable
          if TIMESTAMP_PARTS.has_key?(variable)
            regexp << TIMESTAMP_PARTS[variable]
          else
            raise "Unknown variable: %#{variable}"
          end
        end
      end

      add_blank_option(Regexp.new(regexp), blank)
    end

    # Construct a regular expression to parse IPv4 and IPv6 addresses.
    #
    # Allow nil values if the blank option is given. This can be true to 
    # allow an empty string or to a string substitute for the nil value.
    def ip_address(blank = false)

      # IP address regexp copied from Resolv::IPv4 and Resolv::IPv6, 
      # but adjusted to work for the purpose of request-log-analyzer.
      ipv4_regexp                     = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
      ipv6_regex_8_hex                = /(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}/
      ipv6_regex_compressed_hex       = /(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)/
      ipv6_regex_6_hex_4_dec          = /(?:(?:[0-9A-Fa-f]{1,4}:){6})#{ipv4_regexp}/
      ipv6_regex_compressed_hex_4_dec = /(?:(?:[0-9A-Fa-f]{1,4}(?::[0-9A-Fa-f]{1,4})*)?)::(?:(?:[0-9A-Fa-f]{1,4}:)*)#{ipv4_regexp}/
      ipv6_regexp                     = Regexp.union(ipv6_regex_8_hex, ipv6_regex_compressed_hex, ipv6_regex_6_hex_4_dec, ipv6_regex_compressed_hex_4_dec)

      add_blank_option(Regexp.union(ipv4_regexp, ipv6_regexp), blank)
    end
    
    def anchored(regexp)
      /^#{regexp}$/
    end
    
    protected
    
    # Allow the field to be blank if this option is given. This can be true to 
    # allow an empty string or a string alternative for the nil value.
    def add_blank_option(regexp, blank)
      case blank
        when String; Regexp.union(regexp, Regexp.new(Regexp.quote(blank)))
        when true;   Regexp.union(regexp, //)
        else regexp
      end
    end
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
      @line_definer.define_line(name, &block)
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

    def initialize(line_definitions = OrderedHash.new, report_trackers = [])
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

    # Checks whether the file format is valid so it can be safely used with RLA.
    def well_formed?
      valid_line_definitions? && valid_request_class?
    end
    
    alias_method :valid?, :well_formed?
  

    # Checks whether the line definitions form a valid language.
    # A file format should have at least a header and a footer line type    
    def valid_line_definitions?
      line_definitions.any? { |(_, ld)| ld.header } && line_definitions.any? { |(_, ld)| ld.footer }
    end
    
    # Checks whether the request class inherits from the base Request class.
    def valid_request_class?
      request_class.ancestors.include?(RequestLogAnalyzer::Request)
    end

    # Returns true if this language captures the given symbol in one of its line definitions
    def captures?(name)
      line_definitions.any? { |(_, ld)| ld.captures?(name) }
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
    
    # Returns the max line length for this file format if any.
    def max_line_length
      self.class.const_get(MAX_LINE_LENGTH) if self.class.const_defined?(:MAX_LINE_LENGTH)
    end
    
    def line_divider
      self.class.const_get(LINE_DIVIDER) if self.class.const_defined?(:LINE_DIVIDER)
    end
  end
end
