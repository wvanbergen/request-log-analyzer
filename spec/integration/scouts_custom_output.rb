class EmbeddedHTML < RequestLogAnalyzer::Output::Base
  def print(str)
    @io << str
  end
  alias_method :<<, :print

  def puts(str = "")
    @io << "#{str}<br/>\n"
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

    @io << tag(:table, :cellspacing => 0) do |content|
      if table_has_header?(columns)
        content << tag(:tr) do
          columns.map { |col| tag(:th, col[:title]) }.join("\n")
        end
      end

      odd = false
      rows.each do |row|
        odd = !odd
        content << tag(:tr) do
          if odd
            row.map { |cell| tag(:td, cell, :class => "alt") }.join("\n") 
          else
            row.map { |cell| tag(:td, cell) }.join("\n") 
          end
        end
      end
    end
  end

  def header
  end

  def footer
    @io << tag(:hr) << tag(:p, "Powered by request-log-analyzer v#{RequestLogAnalyzer::VERSION}")
  end

  private

  def tag(tag, content = nil, attributes = nil)
    if block_given?
      attributes = content.nil? ? "" : " " + content.map { |(key, value)| "#{key}=\"#{value}\"" }.join(" ")
      content_string = ""
      content = yield(content_string)
      content = content_string unless content_string.empty? 
      "<#{tag}#{attributes}>#{content}</#{tag}>"
    else
      attributes = attributes.nil? ? "" : " " + attributes.map { |(key, value)| "#{key}=\"#{value}\"" }.join(" ")
      if content.nil?
        "<#{tag}#{attributes} />"
      else
        if content.class == Float
          "<#{tag}#{attributes}><div class='color_bar' style=\"width:#{(content*200).floor}px;\"/></#{tag}>"
        else
          "<#{tag}#{attributes}>#{content}</#{tag}>"
        end
      end
    end
  end  
end
