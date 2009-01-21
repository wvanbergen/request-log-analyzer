module RequestLogAnalyzer::Output
  
  class FixedWidth < Base
  
    module Monochrome
      def colorize(text, *options)
        text
      end
    end
  
    module Color
    
      STYLES = { :normal => 0, :bold => 1, :underscore => 4, :blink => 5, :inverse => 7, :concealed => 8 }
      COLORS = { :black  => 0, :blue => 4, :green => 2, :cyan => 6, :red => 1, :purple => 5, :brown => 3, :white => 7 }
    
      def colorize(text, *options)
    
        font_style       = ''
        foreground_color = '0'
        background_color = ''
      
        options.each do |option|
          if option.kind_of?(Symbol)
            foreground_color = "3#{COLORS[option]}" if COLORS.include?(option)
            font_style       = "#{STYLES[option]};" if STYLES.include?(option)          
          elsif option.kind_of?(Hash)
            options.each do |key, value|
              case key
              when :color;      foreground_color = "3#{COLORS[value]}"  if COLORS.include?(value)
              when :background; background_color = "4#{COLORS[value]};" if COLORS.include?(value)
              when :on;         background_color = "4#{COLORS[value]};" if COLORS.include?(value)
              when :style;      font_style       = "#{STYLES[value]};"  if STYLES.include?(value)
              end
            end
          end
        end
        return "\e[#{background_color}#{font_style}#{foreground_color}m#{text}\e[0m"
      end
    
    end
  
    attr_reader :characters
  
    CHARACTERS = {
      :ascii => { :horizontal_line => '-', :vertical_line => '|', :block => '=' },
      :utf   => { :horizontal_line => '━', :vertical_line => '┃', :block => '░' }
    }
  
    def initialize(io, options = {})
      super(io, options)
      @options[:width]      ||= 80
      @options[:characters] ||= :utf
      @characters = CHARACTERS[@options[:characters]]
    
      color_module = @options[:color] ? Color : Monochrome
      (class << self; self; end).send(:include, color_module) 
    end
  
    def print(str)
      @io << str
    end
  
    alias :<< :print
  
    def puts(str = '')
      @io << str << "\n"
    end
  
    def title(title)
      puts
      puts colorize(title, :bold, :white)
      line(:green)
    end
    
    def line(*font)  
      puts colorize(characters[:horizontal_line] * @options[:width], *font)
    end
  
    def link(text, url = nil)
      if url.nil?
        colorize(text, :blue, :bold)
      else
        "#{text} (#{colorize(url, :blue, :bold)})"
      end
    end
    
    def table(*columns, &block)
    
      rows = Array.new
      yield(rows)

      # determine maximum cell widths
      max_cell_widths = rows.inject(Array.new(columns.length, 0)) do |result, row|
        lengths = row.map { |column| column.to_s.length }
        result.each_with_index { |length, index| result[index] = ([length, lengths[index]].max rescue length) }
      end
      columns.each_with_index { |col, index| col[:actual_width] ||= max_cell_widths[index] }
    
      # determine actual column width
      column_widths = columns.map do |column|
        if column[:width] == :rest
          nil
        elsif column[:width]
          column[:width]
        elsif column[:min_width]
          [column[:min_width], column[:actual_width]].max
        elsif column[:max_width]
          [column[:max_width], column[:actual_width]].min
        else
          column[:actual_width]
        end
      end
     
      if column_widths.include?(nil)
        width_left = options[:width] - ((columns.length - 1) * (style[:cell_separator] ? 3 : 1)) - column_widths.compact.inject(0) { |sum, col| sum + col}
        column_widths[column_widths.index(nil)] = width_left
      end
    
      # Print table header
      if table_has_header?(columns)
        column_titles = []
        columns.each_with_index do |column, index|
          width = column_widths[index]        
          alignment = (column[:align] == :right ? '' : '-')
          column_titles.push(colorize("%#{alignment}#{width}s" % column[:title].to_s[0...width], :bold))
        end
      
        puts column_titles.join(style[:cell_separator] ? " #{characters[:vertical_line]} " : ' ')
        line(:green)
      end
    
      rows.each do |row|
        row_values = []
        columns.each_with_index do |column, index|
          width = column_widths[index]
          case column[:type]
          when :ratio
            if width > 4
              if column[:treshold] && column[:treshold] < row[index].to_f
                bar = ''
                bar << characters[:block] * (width.to_f * column[:treshold]).round 
                bar << colorize(characters[:block] * (width.to_f * (row[index].to_f - column[:treshold])).round, :red) 
                row_values.push(bar) 
              else
                row_values.push(characters[:block] * (width.to_f * row[index].to_f).round) 
              end
            else
              row_values.push('')
            end
          else
            alignment = (columns[index][:align] == :right ? '' : '-')        
            row_values.push("%#{alignment}#{width}s" % row[index].to_s[0...width])
          end
        end
        puts row_values.join(style[:cell_separator] ? " #{characters[:vertical_line]} " : ' ')      
      end
    end
  
  end
end