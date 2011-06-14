module RequestLogAnalyzer::Filter

  # Reject all requests not in given timespan
  # Options
  # * <tt>:after</tt> Only keep requests after this DateTime.
  # * <tt>:before</tt> Only keep requests before this DateTime.
  class Timespan < Base

    attr_reader :before, :after

    def initialize(file_format, options = {})
      @after  = nil
      @before = nil
      super(file_format, options)
      setup_filter
    end


    # Convert the timestamp to the correct formats for quick timestamp comparisons.
    # These are stored in the before and after attr_reader fields.
    def setup_filter
      @after  = @options[:after].strftime('%Y%m%d%H%M%S').to_i  if options[:after]
      @before = @options[:before].strftime('%Y%m%d%H%M%S').to_i if options[:before]
    end

    # Returns request if:
    #   * @after <= request.timestamp <= @before
    #   * @after <= request.timestamp
    #   * request.timestamp <= @before
    # Returns nil otherwise
    # <tt>request</tt> Request object.
    def filter(request)
      if @after && @before && request.timestamp && request.timestamp <= @before && @after <= request.timestamp
        return request
      elsif @after && @before.nil? && request.timestamp && @after <= request.timestamp
        return request
      elsif @before && @after.nil? && request.timestamp && request.timestamp <= @before
        return request
      end

      return nil
    end
  end

end