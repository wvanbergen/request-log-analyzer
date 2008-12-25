module RequestLogAnalyzer
  class Request
  
    attr_reader :lines
    
    def initialize
      @lines = {}
    end
    
    def =~(line_type)
      @lines[line_type.to_sym]
    end
     
    def << (request_info_hash)
      @lines[request_info_hash[:line_type]] = request_info_hash
    end
    
    def [](field)
      @lines.each do |line, fields|
        return fields[field] if fields.has_key?(field)
      end
    end
  end
end