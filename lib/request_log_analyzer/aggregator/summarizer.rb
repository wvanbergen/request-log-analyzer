module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    attr_reader :buckets
    
    def prepare
      @buckets = {}
    end
    
    def aggregate(request)
      if options[:combined_requests]
        bucket_name = bucket_for(request)
        @buckets[bucket_name] ||= default_bucket_info
        update(@buckets[bucket_name], request)
      else
        @buckets[request.line_type] ||= {}
        bucket_name = bucket_for(request)
        @buckets[request.line_type][bucket_name] ||= default_bucket_info
        update(@buckets[request.line_type][bucket_name], request)
      end
    end
    
    def bucket_for(request)
      'all'
    end
          
    def report(color = false)
      if options[:combined_requests]
        @buckets.each do |hash, values|
          puts "  #{hash[0..40].ljust(41)}: #{values[:count]}"
        end     
      else
        @buckets.each do |line_type, buckets|
          puts "Line type #{line_type.inspect}:"
          buckets.each do |hash, values|
            puts "  #{hash[0..40].ljust(41)}: #{values[:count]}"
          end
        end
      end
    end
    
    protected
    
    def default_bucket_info
      { :count => 0 }
    end
    
    def update(bucket, request)
      bucket[:count] += 1
    end
  end
end
