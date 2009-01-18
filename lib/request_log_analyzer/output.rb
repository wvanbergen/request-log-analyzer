module RequestLogAnalyzer
  
  class Output
    
    attr_accessor :io, :options
    
    def self.const_missing(const)
      filename = const.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      require File.dirname(__FILE__) + '/output/' + filename
      self.const_get(const)
    end
    
    def initialize(io, options = {})
      @io = io
      @options = options
    end
    
    protected
    
    def table_has_header?(columns)
      columns.any? { |column| !column[:title].nil? } 
    end
    
  end
end
