module RequestLogAnalyzer
  class Request
  
    attr_reader :lines
    
    def initialize
      @lines = []
    end
    
    def self.create(*hashes)
      request = self.new
      hashes.flatten.each { |hash| request << hash }
      return request
    end
    
    def =~(line_type)
      @lines.detect { |l| l[:line_type] == line_type.to_sym }
    end
     
    def << (request_info_hash)
      @lines << request_info_hash
    end
    
    def [](field)
      @lines.detect { |fields| fields.has_key?(field) }[field] rescue nil
    end
    
    def empty?
      @lines.length == 0
    end
    
    def single_line?
      @lines.length == 1
    end
    
    def combined?
      @lines.length > 1
    end
    
    def line_type
      raise "Not a single line request!" unless single_line?
      lines.first[:line_type]
    end
  end
end