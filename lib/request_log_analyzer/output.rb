# Module for generating output
module RequestLogAnalyzer::Output

  # Load class files if needed
  def self.const_missing(const)
    RequestLogAnalyzer::load_default_class_file(self, const)
  end
  
  # Base Class used for generating output for reports.
  # All output should inherit fromt this class.
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

    # Generate a report table and push it into the output object.
    # Yeilds a rows array into which the rows can be pushed
    # <tt>*colums<tt> Array of Column hashes (see Column options).
    # <tt>&block</tt>: A block yeilding the rows.
    # 
    # === Column options
    # Columns is an array of hashes containing the column definitions.
    # * <tt>:align</tt> Alignment :left or :right
    # * <tt>:treshold</tt> Width in characters or :rest
    # * <tt>:type</tt> :ratio or nil
    # * <tt>:width</tt> Width in characters or :rest
    # 
    # === Example
    # The output object should support table definitions:
    #
    # output.table({:align => :left}, {:align => :right }, {:align => :right}, {:type => :ratio, :width => :rest}) do |rows|        
    #   sorted_frequencies.each do |(cat, count)|
    #     rows << [cat, "#{count} hits", '%0.1f%%' % ((count.to_f / total_hits.to_f) * 100.0), (count.to_f / total_hits.to_f)]
    #   end
    # end
    #
    def table(*columns, &block)
    end
    
    protected
    # Check if a given table defination hash includes a header (title)
    # <tt>columns</tt> The columns hash
    def table_has_header?(columns)
      columns.any? { |column| !column[:title].nil? } 
    end
    
  end
end
