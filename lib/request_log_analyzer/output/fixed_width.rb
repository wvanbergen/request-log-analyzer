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

    column_widths = rows.inject(Array.new(columns.length, 0)) do |result, row|
      lengths = row.map { |column| column.to_s.length }
      
      result.each_with_index do |length, index|
        result[index] = [length, lengths[index]].max rescue length
      end
    end
    
    if table_has_header?(columns)
      column_titles = []
      columns.each_with_index do |column, index|
        column_titles.push("%-#{column_widths[index]}s" % column[0...(column_widths[index])])
      end
    
      puts column_titles.join(" #{characters[:vertical_line]} ")
      puts characters[:horizontal_line] * @options[:width]
    end
    
    rows.each do |row|
      row_values = []
      row.each_with_index do |column, index|
        row_values.push("%-#{column_widths[index]}s" % column.to_s[0...(column_widths[index])])
      end
      puts row_values.join(" #{characters[:vertical_line]} ")      
    end
  end
  
end