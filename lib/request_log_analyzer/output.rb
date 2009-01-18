module RequestLogAnalyzer
  
  class Output
    
    attr_accessor :io, :options, :style
    
    def self.const_missing(const)
      filename = const.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
      require File.dirname(__FILE__) + '/output/' + filename
      self.const_get(const)
    end
    
    def initialize(io, options = {})
      @io      = io
      @options = options
      @style   = options[:style] || { :cell_separator => true, :table_border => false }
    end

    def with_style(temp_style = {})
      old_style = @style
      @style = @style.merge(temp_style)
      yield(self) if block_given?
      @style = old_style
    end    
    
    protected
    
    def table_has_header?(columns)
      columns.any? { |column| !column[:title].nil? } 
    end
    
  end
end
