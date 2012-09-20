# coding: utf-8
module RequestLogAnalyzer::Output

  # Fixed Width output class.
  # Outputs a fixed width ASCII or UF8 report.
  class FixedWidth < Base

    # Mixin module. Will disable any colorizing.
    module Monochrome
      def colorize(text, *options)
        text
      end
    end

    # Colorize module
    module Color

      STYLES = { :normal => 0, :bold => 1, :underscore => 4, :blink => 5, :inverse => 7, :concealed => 8 }
      COLORS = { :black  => 0, :blue => 4, :green => 2, :cyan => 6, :red => 1, :purple => 5, :brown => 3, :white => 7 }

      # Colorize text
      # <tt>text</tt> The text to colorize
      # Options
      #  * <tt>:background</tt> The background color to paint. Defined in Color::COLORS
      #  * <tt>:color</tt> The foreground color to paint. Defined in Color::COLORS
      #  * <tt>:on</tt> Alias for :background
      #  * <tt>:style</tt> Font style, defined in Color::STYLES
      #
      # Returns ASCII colored string
      def colorize(text, *options)

        font_style       = ''
        foreground_color = '0'
        background_color = ''

        options.each do |option|
          if option.kind_of?(Symbol)
            foreground_color = "3#{COLORS[option]}" if COLORS.include?(option)
            font_style       = "#{STYLES[option]};" if STYLES.include?(option)
          elsif option.kind_of?(Hash)
            option.each do |key, value|
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

    # Initialize a report
    # <tt>io</tt> iO Object (file, STDOUT, etc.)
    # <tt>options</tt>
    #  * <tt>:characters</tt> :utf for UTF8 or :ascii for ANSI compatible output. Defaults to :utf.
    #  * <tt>:color</tt> If true, ASCII colorization is used, else Monochrome. Defaults to Monochrome.
    #  * <tt>:width</tt> Output width in characters. Defaults to 80.
    def initialize(io, options = {})
      super(io, options)
      @options[:width]      ||= 80
      @options[:characters] ||= :utf
      @characters = CHARACTERS[@options[:characters]]

      color_module = @options[:color] ? Color : Monochrome
      (class << self; self; end).send(:include, color_module)
    end

    # Write a string to the output object.
    # <tt>str</tt> The string to write.
    def print(str)
      @io << str
    end

    alias :<< :print

    # Write a string to the output object with a newline at the end.
    # <tt>str</tt> The string to write.
    def puts(str = '')
      @io << str << "\n"
    end

    # Write the title of a report
    # <tt>title</tt> The title to write
    def title(title)
      puts
      puts colorize(title, :bold, :white)
      line(:green)
    end

    # Write a line
    def line(*font)
      puts colorize(characters[:horizontal_line] * @options[:width], *font)
    end

    # Write a link
    # <tt>text</tt> The text in the link, or the URL itself if no text is given
    # <tt>url</tt> The url to link to.
    def link(text, url = nil)
      if url.nil?
        colorize(text, :red, :bold)
      else
        "#{text} (#{colorize(url, :blue, :bold)})"
      end
    end

    # Generate a header for a report
    def header
      if io.kind_of?(File)
        puts colorize("Request-log-analyzer summary report", :white, :bold)
        line(:green)
        puts "Version #{RequestLogAnalyzer::VERSION} - written by Willem van Bergen and Bart ten Brinke"
        puts "Website: #{link('http://github.com/wvanbergen/request-log-analyzer')}"
      end
    end

    # Generate a footer for a report
    def footer
      puts
      puts "Need an expert to analyze your application?"
      puts "Mail to #{link('contact@railsdoctors.com')} or visit us at #{link('http://railsdoctors.com')}."
      line(:green)
      puts "Thanks for using #{colorize('request-log-analyzer', :white, :bold)}!"
    end

    # Generate a report table and push it into the output object.
    # <tt>*colums<tt> Columns hash
    # <tt>&block</tt>: A block yeilding the rows.
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

      line(:green) if @style[:top_line]

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

      # Print the rows
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
                # Create a bar by combining block characters
                row_values.push(characters[:block] * (width.to_f * row[index].to_f).round)
              end
            else
              # Too few characters for a ratio bar. Display nothing
              row_values.push('')
            end
          else
            alignment = (columns[index][:align] == :right ? '' : '-')
            cell_value = "%#{alignment}#{width}s" % row[index].to_s[0...width]
            cell_value = colorize(cell_value, :bold, :brown) if columns[index][:highlight]
            row_values.push(cell_value)
          end
        end
        puts row_values.join(style[:cell_separator] ? " #{characters[:vertical_line]} " : ' ')
      end
    end

  end
end