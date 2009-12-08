module RequestLogAnalyzer::Output

  # HTML Output class. Generated a HTML-formatted report, including CSS.
  class HTML < Base

    # def initialize(io, options = {})
    #   super(io, options)
    # end

    def colorize(text, *style)
      if style.include?(:bold)
        tag(:strong, text)
      else
        text
      end
    end

    # Print a string to the io object.
    def print(str)
      @io << str
    end

    alias :<< :print

    # Put a string with newline
    def puts(str = '')
      @io << str << "<br/>\n"
    end

    # Place a title
    def title(title)
      @io.puts(tag(:h2, title))
    end

    # Render a single line
    # <tt>*font</tt> The font.
    def line(*font)
      @io.puts(tag(:hr))
    end

    # Write a link
    # <tt>text</tt> The text in the link
    # <tt>url</tt> The url to link to.
    def link(text, url = nil)
      url = text if url.nil?
      tag(:a, text, :href => url)
    end

    # Generate a report table in HTML and push it into the output object.
    # <tt>*colums<tt> Columns hash
    # <tt>&block</tt>: A block yeilding the rows.
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

    # Genrate HTML header and associated stylesheet
    def header
      @io.content_type = content_type if @io.respond_to?(:content_type)

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
      @io << tag(:p, "Version #{RequestLogAnalyzer::VERSION} - written by Willem van Bergen and Bart ten Brinke")
    end

    # Generate a footer for a report
    def footer
      @io << tag(:hr) << tag(:h2, 'Thanks for using request-log-analyzer')
      @io << tag(:p, 'For more information please visit the ' + link('Request-log-analyzer website', 'http://github.com/wvanbergen/request-log-analyzer'))
      @io << tag(:p, 'If you need an expert who can analyze your application, mail to ' + link('contact@railsdoctors.com', 'mailto:contact@railsdoctors.com') + ' or visit us at ' + link('http://railsdoctors.com', 'http://railsdoctors.com') + '.')
      @io << "</body></html>\n"
    end

    protected

    # HTML tag writer helper
    # <tt>tag</tt> The tag to generate
    # <tt>content</tt> The content inside the tag
    # <tt>attributes</tt> Attributes to write in the tag
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