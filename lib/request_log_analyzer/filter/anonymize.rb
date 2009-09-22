module RequestLogAnalyzer::Filter

  # Filter to anonymize parsed values
  # Options
  # * <tt>:mode</tt> :reject or :accept.
  # * <tt>:field</tt> Specific field to accept or reject.
  # * <tt>:value</tt> Value that the field should match to be accepted or rejected.
  class Anonymize < Base

    def generate_random_ip
      "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}"
    end

    def anonymize_url(value)
      return value.sub(/^https?\:\/\/[A-Za-z0-9\.-]+\//, "http://example.com/")
    end

    def fuzz(value)
      value * ((75 + rand(50)) / 100.0)
    end

    def filter(request)
      # TODO: request.attributes is bad practice
      request.attributes.each do |key, value|
        if key == :ip
          request.attributes[key] = generate_random_ip
        elsif key == :url
          request.attributes[key] = anonymize_url(value)
        elsif [ :duration, :view, :db, :type, :after_filters_time, :before_filters_time,
                :action_time].include?(key)
          request.attributes[key] = fuzz(value)
        end
      end

      return request
    end
  end

end
