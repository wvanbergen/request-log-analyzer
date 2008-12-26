module RequestLogAnalyzer::Aggregator

  class Summarizer < Base
    
    attr_reader :buckets
    
    def prepare
      @buckets = {}
    end
    
    def aggregate(request)
      if options[:combined_requests]
        current_bucket_hash = @buckets
      else       
        @buckets[request.line_type] ||= {}
        current_bucket_hash = @buckets[request.line_type]
      end
      
      bucket_name = bucket_for(request)
      current_bucket_hash[bucket_name] ||= default_bucket_content
      update_bucket(current_bucket_hash[bucket_name], request)
    end
    
    def default_bucket_content
      return { :count => 0 }
    end
    
    def update_bucket(bucket, request)
      bucket[:count] += 1
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
    

  end
end
