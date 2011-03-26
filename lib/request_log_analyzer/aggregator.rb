module RequestLogAnalyzer::Aggregator

  # The base class of an aggregator. This class provides the interface to which
  # every aggregator should comply (by simply subclassing this class).
  class Base

    attr_reader :options, :source

    # Intializes a new RequestLogAnalyzer::Aggregator::Base instance
    # It will include the specific file format module.
    def initialize(source, options = {})
      @source = source
      @options = options
    end

    # The prepare function is called just before parsing starts. This function
    # can be used to initialie variables, etc.
    def prepare
    end

    # The aggregate function is called for every request.
    # Implement the aggregating functionality in this method
    def aggregate(request)
    end

    # The finalize function is called after all sources are parsed and no more
    # requests will be passed to the aggregator
    def finalize
    end

    # The warning method is called if the parser eits a warning.
    def warning(type, message, lineno)
    end

    # The report function is called at the end. Implement any result reporting
    # in this function.
    def report(output)
    end

    # The source_change function gets called when handling a source is started or finished.
    def source_change(change, filename)
    end

  end
end

require 'request_log_analyzer/aggregator/echo'
require 'request_log_analyzer/aggregator/summarizer'
require 'request_log_analyzer/aggregator/database_inserter'
