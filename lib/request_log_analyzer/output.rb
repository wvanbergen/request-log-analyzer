# Class used for generating outputs
module RequestLogAnalyzer::Output

  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end
  
  class Base
    
    attr_accessor :io, :options, :style
    
    # Initialize a report
    # <tt>io</tt> iO Object (file, STDOUT, etc.)
    # <tt>options</tt> Specific style options
    def initialize(io, options = {})
      @io      = io
      @options = options
      @style   = options[:style] || { :cell_separator => true, :table_border => false }
    end

    # Apply a style block.. with style :)
    def with_style(temp_style = {})
      old_style = @style
      @style = @style.merge(temp_style)
      yield(self) if block_given?
      @style = old_style
    end    
    
    # Generate a header for a report
    def header
    end
    
    # Generate the footer of a report 
    def footer
    end
    
    protected
    # Check if a given table defination hash includes a header (title)
    # <tt>columns</tt> The columns hash
    def table_has_header?(columns)
      columns.any? { |column| !column[:title].nil? } 
    end
    
  end
end
