module RequestLogAnalyzer::Output

  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end
  
  class Base
    
    attr_accessor :io, :options, :style
    
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
    
    def header
    end
    
    def footer
    end
    
    protected
    
    def table_has_header?(columns)
      columns.any? { |column| !column[:title].nil? } 
    end
    
  end
end
