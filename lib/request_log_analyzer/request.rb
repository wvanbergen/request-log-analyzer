module RequestLogAnalyzer
  class Request
  
    include RequestLogAnalyzer::FileFormat
  
    attr_reader :lines
    
    def initialize(file_format)
      @lines = []
      register_file_format(file_format)
    end
    
    def self.create(file_format, *hashes)
      request = self.new(file_format)
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
    
    def completed?
      header_found, footer_found = false, false
      @lines.each do |line| 
        line_def = file_format.line_definitions[line[:line_type]]
        header_found = true if line_def.header
        footer_found = true if line_def.footer        
      end
      header_found && footer_found
    end
        
    def line_type
      raise "Not a single line request!" unless single_line?
      lines.first[:line_type]
    end
  end
end