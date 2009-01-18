class RequestLogAnalyzer::Output::HTML < RequestLogAnalyzer::Output

  # def initialize(io, options = {})
  #   super(io, options)
  # end

  def print(str)
    @io << str
  end

  alias :<< :print

  def puts(str = '')
    @io << str << "<br />\n"
  end

  def title(title)
    @io.puts(tag(:h2, title))
  end

  def line(*font)  
    @io.puts(tag(:hr))
  end

  def link(text, url = nil)
    url = text if url.nil?
    tag(:a, text, :href => url)
  end

  def table(*columns, &block)
    rows = Array.new
    yield(rows)
    
    @io << tag(:table) do |content|
      if table_has_header?(columns)
        content << tag(:tr) do
          columns.map { |col| tag(:th, col[:title]) }.join("\n")
        end
      end
      
      rows.each do |row|
        content << tag(:tr) do
          row.map { |cell| tag(:td, cell) }.join("\n") 
        end
      end
    end
    
  end
  
  def header
    @io << "<html>"
    @io << tag(:head) do |headers|
      headers << tag(:title, 'Request-log-analyzer report')
    end
    @io << '<body>'
  end
  
  def footer
    @io << "</body></html>\n"
  end
  
  protected 
  
  def tag(tag, content = nil, attributes = nil)
    if block_given?
      attributes = content.nil? ? '' : ' ' + content.map { |(key, value)| "#{key}=\"#{value}\"" }.join(' ')
      content_string = ''
      content = yield(content_string)
      content = content_string unless content_string.empty? 
      "<#{tag}#{attributes}>#{content}</#{tag}>"
    else
      attributes = attributes.nil? ? '' : ' ' + attributes.map { |(key, value)| "#{key}=\"#{value}\"" }.join(' ')
      if content.nil?
        "<#{tag}#{attributes} />"
      else
        "<#{tag}#{attributes}>#{content}</#{tag}>"
      end
    end
  end  
end