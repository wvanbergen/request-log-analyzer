module RequestLogAnalyzer::Tracker

  # Analyze the average and total traffic of requests
  #
  # === Options
  # * <tt>:category</tt> Proc that handles request categorization for given fileformat (REQUEST_CATEGORIZER)
  # * <tt>:traffic</tt> The field containing the duration in the request hash.
  # * <tt>:if</tt> Proc that has to return !nil for a request to be passed to the tracker.
  # * <tt>:line_type</tt> The line type that contains the duration field (determined by the category proc).
  # * <tt>:title</tt> Title do be displayed above the report
  # * <tt>:unless</tt> Handle request if this proc is false for the handled request.
  class Traffic < NumericValue

    # Check if duration and catagory option have been received,
    def prepare
      options[:value] = options[:traffic] if options[:traffic]
      options[:total] = true
      super
      
      @number_of_buckets = options[:number_of_buckets] || 1000
      @min_bucket_value  = options[:min_bucket_value] ? options[:min_bucket_value].to_f : 1
      @max_bucket_value  = options[:max_bucket_value] ? options[:max_bucket_value].to_f : 1000_000_000_000

      # precalculate the bucket size
      @bucket_size = (Math.log(@max_bucket_value) - Math.log(@min_bucket_value)) / @number_of_buckets.to_f
    end

    # Formats the traffic number using x B/kB/MB/GB etc notation
    def display_value(bytes)
      return "-"   if bytes.nil?
      return "0 B" if bytes.zero?
      
      case [Math.log10(bytes.abs).floor, 0].max
      when  0...4  then '%d B'  % bytes
      when  4...7  then '%d kB' % (bytes / 1000)
      when  7...10 then '%d MB' % (bytes / 1000_000)
      when 10...13 then '%d GB' % (bytes / 1000_000_000)
      else              '%d TB' % (bytes / 1000_000_000_000)
      end
    end

    # Returns the title of this tracker for reports
    def title
      options[:title]  || 'Request traffic'
    end
  end
end
