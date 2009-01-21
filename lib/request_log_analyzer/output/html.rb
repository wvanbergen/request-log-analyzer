module RequestLogAnalyzer::Output
  
  class HTML < Base
  
    # def initialize(io, options = {})
    #   super(io, options)
    # end
  
    def print(str)
      @io << str
    end

    alias :<< :print

    def puts(str = '')
      @io << str << "<br/>\n"
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
    
      @io << tag(:table, {:id => 'mytable', :cellspacing => 0}) do |content|
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
              row.map { |cell| tag(:td, cell, :class => 'alt') }.join("\n") 
            else
              row.map { |cell| tag(:td, cell) }.join("\n") 
            end
          end
        end
      end
    
    end
  
    def header
      @io << "<html>"
      @io << tag(:head) do |headers|
        headers << tag(:title, 'Request-log-analyzer report')
        headers << tag(:style, '
        body {
        	font: normal 11px auto "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
        	color: #4f6b72;
        	background: #E6EAE9;
        	padding-left:20px;
        	padding-top:20px;
        	padding-bottom:20px;
        }

        a {
        	color: #c75f3e;
        }
      
        .color_bar {
          border: 1px solid;
          height:10px;
        	background: #CAE8EA;
        }
      
        #mytable {
        	width: 700px;
        	padding: 0;
        	margin: 0;
        	padding-bottom:10px;
        }

        caption {
        	padding: 0 0 5px 0;
        	width: 700px;	 
        	font: italic 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
        	text-align: right;
        }

        th {
        	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
        	color: #4f6b72;
        	border-right: 1px solid #C1DAD7;
        	border-bottom: 1px solid #C1DAD7;
        	border-top: 1px solid #C1DAD7;
        	letter-spacing: 2px;
        	text-transform: uppercase;
        	text-align: left;
        	padding: 6px 6px 6px 12px;
        	background: #CAE8EA url(images/bg_header.jpg) no-repeat;
        }

        td {
        	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
        	border-right: 1px solid #C1DAD7;
        	border-bottom: 1px solid #C1DAD7;
        	background: #fff;
        	padding: 6px 6px 6px 12px;
        	color: #4f6b72;
        }

        td.alt {
        	background: #F5FAFA;
        	color: #797268;
        }
        ', :type => "text/css")
      end
      @io << '<body>'
      @io << tag(:h1, 'Request-log-analyzer summary report')
      @io << tag(:p, 'Version 1.1 - written by Willem van Bergen and Bart ten Brinke')
    end
  
    def footer
      @io << tag(:hr) << tag(:h2, 'Thanks for using request-log-analyzer')
      @io << tag(:p, 'Please visit the ' + link('Request-log-analyzer website', 'http://github.com/wvanbergen/request-log-analyzer'))
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
          if content.class == Float
            "<#{tag}#{attributes}><div class='color_bar' style=\"width:#{(content*200).floor}px;\"/></#{tag}>"
          else
            "<#{tag}#{attributes}>#{content}</#{tag}>"
          end
        end
      end
    end  
  end
end