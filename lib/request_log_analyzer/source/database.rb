require 'rubygems'
require 'activerecord'

module RequestLogAnalyzer::Source
  
  # Active Resource hook
  class Request < ActiveRecord::Base
    has_many :completed_lines
    has_many :processing_lines
    def convert(file_format)
      send_attributes = self.attributes
      send_attributes.merge!(self.completed_lines.first.attributes) if self.completed_lines.first
      send_attributes.merge!(self.processing_lines.first.attributes) if self.processing_lines.first
      return RequestLogAnalyzer::Request.new(file_format, send_attributes)
    end
  end

  class CompletedLine < ActiveRecord::Base
    belongs_to :request
  end

  class ProcessingLine < ActiveRecord::Base
    belongs_to :request
  end

  # The Database class gets log data from the database.
  class Database < Base

    attr_reader :source_files
    attr_reader :requests

    # Initializes the log file parser instance.
    # It will apply the language specific FileFormat module to this instance. It will use the line
    # definitions in this module to parse any input that it is given (see parse_io).
    #
    # <tt>format</tt>:: The current file format instance
    # <tt>options</tt>:: A hash of options that are used by the parser
    def initialize(format, options = {})      
      @line_definitions = {}
      @options          = options
      @source_files     = options[:source_files]
      @parsed_requests  = 0
      @requests         = []
      
      self.register_file_format(format)
    end
    
    # Reads the input, which can either be a file, sequence of files or STDIN to parse
    # lines specified in the FileFormat. This lines will be combined into Request instances,
    # that will be yielded. The actual parsing occurs in the parse_io method.
    # <tt>options</tt>:: A Hash of options that will be pased to parse_io.
    def each_request(options = {}, &block) # :yields: request
      ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => @source_files)

      @progress_handler.call(:started, @source_files) if @progress_handler
        RequestLogAnalyzer::Source::Request.find(:all).each do |request|
          @parsed_requests += 1
          @progress_handler.call(:progress, @parsed_requests) if @progress_handler
          
          yield request.convert(self.file_format)
        end
      
      @progress_handler.call(:finished, @source_files) if @progress_handler
    end

    # Add a block to this method to install a progress handler while parsing.
    # <tt>proc</tt>:: The proc that will be called to handle progress update messages
    def progress=(proc)
      @progress_handler = proc
    end

    # Add a block to this method to install a warning handler while parsing,
    # <tt>proc</tt>:: The proc that will be called to handle parse warning messages    
    def warning=(proc)
      @warning_handler = proc
    end

    # This method is called by the parser if it encounteres any parsing problems.
    # It will call the installed warning handler if any. 
    #
    # By default, RequestLogAnalyzer::Controller will install a warning handler 
    # that will pass the warnings to each aggregator so they can do something useful
    # with it.
    #
    # <tt>type</tt>:: The warning type (a Symbol)
    # <tt>message</tt>:: A message explaining the warning
    def warn(type, message)
      @warning_handler.call(type, message, @current_io.lineno) if @warning_handler
    end
  end
end