class RequestLogAnalyzer::Output::FixedWidth < RequestLogAnalyzer::Output
  
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
    puts title
    puts characters[:horizontal_line] * @options[:width]
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
        [column[:min_width], col[:actual_width]].max
      elsif column[:max_width]
        [column[:max_width], col[:actual_width]].min
      else
        column[:actual_width]
      end
    end
     
    if column_widths.include?(nil)
      width_left = options[:width] - ((columns.length - 1) * 3) - column_widths.compact.inject(0) { |sum, col| sum + col}
      column_widths[column_widths.index(nil)] = width_left
    end
    
    # Print table header
    if table_has_header?(columns)
      column_titles = []
      columns.each_with_index do |column, index|
        alignment = (column[:align] == :right ? '' : '-')
        column_titles.push("%#{alignment}#{column_widths[index]}s" % column[:title].to_s[0...(column_widths[index])])
      end
      
      puts
      puts column_titles.join(" #{characters[:vertical_line]} ")
      puts characters[:horizontal_line] * @options[:width]
    end
    
    rows.each do |row|
      row_values = []
      row.each_with_index do |column, index|
        width = column_widths[index]
        case columns[index][:type]
        when :ratio
          row_values.push(characters[:block] * (width.to_f * column.to_f).round)
        else
          alignment = (columns[index][:align] == :right ? '' : '-')        
          row_values.push("%#{alignment}#{width}s" % column.to_s[0...width])
        end
      end
      puts row_values.join(" #{characters[:vertical_line]} ")      
    end
  end
  
end