module RequestLogAnalyzer::Filter
  
  # Filter to select or reject a specific field
  # Options
  # * <tt>:mode</tt> :reject or :accept.
  # * <tt>:field</tt> Specific field to accept or reject.
  # * <tt>:value</tt> Value that the field should match to be accepted or rejected.
  class Anonimize < Base
   
    def prepare
    end

    def generate_random_ip
      "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}"
    end

    def anonymize_url(value)
      value.sub(/^https?\:\/\/[A-z0-9\.-]+\//, "http://example.com/")
    end
    
    def fuzz(value)
      value * ((75 + rand(50)) / 100.0)
    end

    def filter(request)
      return nil unless request
      
      request.each do |key, value|
        if key == :ip
          value = generate_random_ip
        elsif key == :url
          value == anonymize_url
        elsif [ :duration, :view, :db, :type, :after_filters_time, :before_filters_time,
                :action_time].include?(key)
          value == fuzz(value)
        end
      end
      
      return request
    end 
  end
  
end
