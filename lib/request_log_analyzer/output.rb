# Module for generating output
module RequestLogAnalyzer::Output

  # Loads a Output::Base subclass instance.
  def self.load(file_format, *args)
    
    klass = nil
    if file_format.kind_of?(RequestLogAnalyzer::Output::Base)
      # this already is a file format! return itself
      return file_format

    elsif file_format.kind_of?(Class) && file_format.ancestors.include?(RequestLogAnalyzer::Output::Base)
      # a usable class is provided. Use this format class.
      klass = file_format

    elsif file_format.kind_of?(String) && File.exist?(file_format)
      # load a format from a ruby file
      require file_format
      const = RequestLogAnalyzer.to_camelcase(File.basename(file_format, '.rb'))
      if RequestLogAnalyzer::FileFormat.const_defined?(const)
        klass = RequestLogAnalyzer::Output.const_get(const)
      elsif Object.const_defined?(const)
        klass = Object.const_get(const)
      else
        raise "Cannot load class #{const} from #{file_format}!"
      end

    else
      # load a provided file format
      klass = RequestLogAnalyzer::Output.const_get(RequestLogAnalyzer.to_camelcase(file_format))
    end

    # check the returned klass to see if it can be used
    raise "Could not load a file format from #{file_format.inspect}" if klass.nil?
    raise "Invalid FileFormat class" unless klass.kind_of?(Class) && klass.ancestors.include?(RequestLogAnalyzer::Output::Base)

    klass.create(*args) # return an instance of the class
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
    
    def report_tracker(tracker)
      tracker.report(self)
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

    def slice_results(array)
      return array if options[:amount] == :all
      return array.slice(0, options[:amount]) # otherwise
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

require 'request_log_analyzer/output/fixed_width'
require 'request_log_analyzer/output/html'
