require 'spec_helper'

def capture_stdout_and_stderr_with_warnings_on
  $stdout, $stderr, warnings, $VERBOSE =
    StringIO.new, StringIO.new, $VERBOSE, true
  yield
  return $stdout.string, $stderr.string
ensure
  $stdout, $stderr, $VERBOSE = STDOUT, STDERR, warnings
end

describe RequestLogAnalyzer, 'when using the rla API like the scout plugin' do
  
  before(:each) do
    # prepare a place to capture the output
    sio = StringIO.new
    
    # place an IO object where I want RequestLogAnalyzer to read from
    open(log_fixture(:rails_1x)) do |log|
      completed_count = 0
      log.each do |line|
        completed_count += 1 if line =~ /\ACompleted\b/
        break if completed_count == 2  # skipping first two requests
      end
      
      # trigger the log parse
      @stdout, @stderr = capture_stdout_and_stderr_with_warnings_on do
        RequestLogAnalyzer::Controller.build(
          :output       => EmbeddedHTML,
          :file         => sio,
          :after        => Time.local(2008, 8, 14, 21, 16, 31),  # after 3rd req
          :source_files => log,
          :format        => RequestLogAnalyzer::FileFormat::Rails
        ).run!
      end
    end
    
    # read the resulting output
    @analysis = sio.string
  end
  
  it "should generate an analysis" do
    @analysis.should_not be_empty
  end
  
  it "should generate customized output using the passed Class" do
    credit = %r{<p>Powered by request-log-analyzer v\d+(?:\.\d+)+</p>\z}
    @analysis.should match(credit)
  end
  
  it "should skip requests before :after Time" do
    @analysis.should_not include("PeopleController#show")
  end
  
  it "should include requests after IO#pos and :after Time" do
    @analysis.should include("PeopleController#picture")
  end
  
  it "should skip requests before IO#pos" do
    @analysis.should_not include("PeopleController#index")
  end
  
  it "should not print to $stdout" do
    @stdout.should be_empty
  end
  
  it "should not print to $stderr (with warnings on)" do
    @stderr.should be_empty
  end

end

# Helpers
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

