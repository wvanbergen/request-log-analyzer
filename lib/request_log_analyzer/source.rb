# The RequestLogAnalyzer::Source module contains all functionality that loads requests from a given source
# and feed them to the pipeline for further processing. The requests (see RequestLogAnalyzer::Request) that
# will be parsed from a source, will be piped throug filters (see RequestLogAnalyzer::Filter) and are then
# fed to an aggregator (see RequestLogAnalyzer::Aggregator). The source instance is thus the beginning of
# the RequestLogAnalyzer chain.
#
# - The base class for all sources is RequestLogAnalyzer::Source::Base. All source classes should inherit from this class.
# - Currently, RequestLogAnalyzer::Source::LogParser is the only implemented source.
module RequestLogAnalyzer::Source

  # The base Source class. All other sources should inherit from this class.
  #
  # A source implememtation should at least implement the each_request method, which should yield
  # RequestLogAnalyzer::Request instances that will be fed through the pipleine.
  class Base

    # A hash of options
    attr_reader :options

    # The current Request object that is being parsed
    attr_reader :current_request

    # The total number of parsed lines
    attr_reader :parsed_lines

    # The number of skipped lines because of warnings
    attr_reader :skipped_lines

    # The total number of parsed requests.
    attr_reader :parsed_requests

    # The total number of skipped requests because of filters.
    attr_reader :skipped_requests

    # The FileFormat instance that describes the format of this source.
    attr_reader :file_format

    # Initializer, which will register the file format and save any options given as a hash.
    # <tt>format</tt>:: The file format instance
    # <tt>options</tt>:: A hash of options that can be used by a specific Source implementation
    def initialize(format, options = {})
      @options     = options
      @file_format = format
    end

    # The prepare method is called before the RequestLogAnalyzer::Source::Base#each_request method is called.
    # Use this method to implement any initialization that should occur before this source can produce Request
    # instances.
    def prepare
    end

    # This function is called to actually produce the requests that will be send into the pipeline.
    # The implementation should yield instances of RequestLogAnalyzer::Request.
    # <tt>options</tt>:: A Hash of options that can be used in the implementation.
    def each_request(options = {}, &block) # :yields: request
      return true
    end

    # This function is called after RequestLogAnalyzer::Source::Base#each_request finished. Any code to
    # wrap up, free resources, etc. can be put in this method.
    def finalize
    end

  end
end

require 'request_log_analyzer/source/log_parser'
