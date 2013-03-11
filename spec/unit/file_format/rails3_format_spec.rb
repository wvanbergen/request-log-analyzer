require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails3 do

  subject { RequestLogAnalyzer::FileFormat.load(:rails3) }

  it { should be_well_formed }
  it { should have(11).report_trackers }

  describe '#parse_line' do

    it "should parse :started lines correctly" do
      line = 'Started GET "/queries" for 127.0.0.1 at Thu Feb 25 16:15:18 -0800 2010'
      subject.should parse_line(line).as(:started).and_capture(:method => 'GET',
            :path => '/queries', :ip => '127.0.0.1', :timestamp => 20100225161518)
    end

    it "should parse :started lines in Oct, Nov and Dec correctly" do
      line = 'Started GET "/queries" for 127.0.0.1 at Thu Oct 25 16:15:18 -0800 2010'
      subject.should parse_line(line).as(:started).and_capture(:method => 'GET',
            :path => '/queries', :ip => '127.0.0.1', :timestamp => 20101025161518)
    end

    it "should parse :started lines in Ruby 1.9.2 format correctly" do
      line = 'Started GET "/queries" for 127.0.0.1 at 2010-10-26 02:27:15 +0000'
      subject.should parse_line(line).as(:started).and_capture(:method => 'GET',
            :path => '/queries', :ip => '127.0.0.1', :timestamp => 20101026022715)
    end

    it "should parse :processing lines correctly" do
      line = ' Processing by QueriesController#index as HTML'
      subject.should parse_line(line).as(:processing).and_capture(
        :controller => 'QueriesController', :action => 'index', :format => 'HTML')
    end

    it "should parse nested :processing lines correctly" do
      line = ' Processing by Projects::QueriesController#index as HTML'
      subject.should parse_line(line).as(:processing).and_capture(
        :controller => 'Projects::QueriesController', :action => 'index', :format => 'HTML')
    end

    it "should parse :processing lines correctly with format */*" do
      line = '  Processing by ProjectsController#avatar as */*'
      subject.should parse_line(line).as(:processing).and_capture(
        :controller => 'ProjectsController', :action => 'avatar', :format => '*/*')
    end

    it "should parse :processing lines correctly without format" do
      line = '  Processing by ProjectsController#avatar as '
      subject.should parse_line(line).as(:processing).and_capture(
        :controller => 'ProjectsController', :action => 'avatar', :format => '')
    end

    it "should parse a :parameters line correctly" do
      line = '  Parameters: {"action"=>"cached", "controller"=>"cached"}'
      subject.should parse_line(line).as(:parameters).and_capture(:params => {:action => 'cached', :controller => 'cached'})
    end

    it "should parse a :parameters line with no indentation correctly" do
      line = 'Parameters: {"action"=>"cached", "controller"=>"cached"}'
      subject.should parse_line(line).as(:parameters).and_capture(:params => {:action => 'cached', :controller => 'cached'})
    end

    it "should parse :completed lines correctly" do
      line = 'Completed 200 OK in 170ms (Views: 78.0ms | ActiveRecord: 48.2ms)'
      subject.should parse_line(line).as(:completed).and_capture(
          :duration => 0.170, :view => 0.078, :db => 0.0482, :status => 200)
    end

    it "should parse :completed lines correctly when ActiveRecord is not mentioned" do
      line = 'Completed 200 OK in 364ms (Views: 31.4ms)'
      subject.should parse_line(line).as(:completed).and_capture(:duration => 0.364, :status => 200)
    end

    it "should parse :completed lines correctly when other durations are specified" do
      line = 'Completed 200 OK in 384ms (Views: 222.0ms | ActiveRecord: 121.0ms | Sphinx: 0.0ms)'
      subject.should parse_line(line).as(:completed).and_capture(:duration => 0.384, :view => 0.222,
          :db => 0.121, :status => 200)
    end

    it "should parse :routing_error lines correctly" do
      line = "ActionController::RoutingError (No route matches [GET] \"/static/faq\"):"
      subject.should parse_line(line).as(:routing_errors).and_capture(:missing_resource_method => "GET",
          :missing_resource  => '/static/faq')
    end

    it "should parse :failure lines correctly" do
      line = "ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/willem/Code/warehouse/app/views/queries/execute.csv.erb:"
      subject.should parse_line(line).as(:failure).and_capture(:line => 3,
          :error   => 'ActionView::Template::Error',
          :message => "undefined local variable or method `field' for #<Class>",
          :file    => '/Users/willem/Code/warehouse/app/views/queries/execute.csv.erb')
    end

    it "should parse :rendered lines as an array" do
      line = " Rendered queries/index.html.erb (0.6ms)"
      subject.should parse_line(line).as(:rendered).and_capture(:partial_duration => [0.0006])
    end

    it "should parse :rendered lines with no identation as an array" do
      line = "Rendered queries/index.html.erb (0.6ms)"
      subject.should parse_line(line).as(:rendered).and_capture(:partial_duration => [0.0006])
    end
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject) }

    it "should parse a successful request correctly" do
      log = <<-EOLOG
        Started GET "/" for 127.0.0.1 at Fri Mar 19 06:40:41 -0700 2010
          Processing by QueriesController#index as HTML
          SQL (16.3ms)  SHOW TABLES
          Query Load (32.0ms)  SELECT `queries`.* FROM `queries`
        Rendered queries/index.html.erb within layouts/default (40.9ms)
        Completed 200 OK in 170ms (Views: 78.4ms | ActiveRecord: 48.2ms)
      EOLOG

      log_parser.should_receive(:handle_request).once
      log_parser.should_not_receive(:warn)
      log_parser.parse_string(log)
    end

    it "should count partials correctly" do
      log = <<-EOLOG
        Started GET "/stream_support" for 127.0.0.1 at 2012-11-21 15:21:31 +0100
        Processing by HomeController#stream_support as */*
          Rendered home/stream_support.html.slim (33.2ms)
          Rendered home/stream_support.html.slim (0.0ms)
        Completed 200 OK in 2ms (Views: 0.6ms | ActiveRecord: 0.0ms)
      EOLOG

      log_parser.parse_string(log)
    end

    it "should parse a failing request correctly" do
      log = <<-EOLOG
        Started POST "/queries/397638749/execute.csv" for 127.0.0.1 at Mon Mar 01 18:44:33 -0800 2010
          Processing by QueriesController#execute as CSV
          Parameters: {"commit"=>"Run query", "authenticity_token"=>"pz9WcxkcrlG/43eg6BgSAnJL7yIsaffuHbYxPHUsUzQ=", "id"=>"397638749"}

        ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/application/app/views/queries/execute.csv.erb:
        1: <%=raw @result.fields.map { |f| f.humanize.to_json }.join(',') %>
        2: <% @result.each do |record| %>
        3:   <%=raw @result.fields.map { |f| record[field].to_s }.join(",") %>
        4: <% end %>

            app/views/queries/execute.csv.erb:3:in `_render_template__652100315_2182241460_0'
            app/views/queries/execute.csv.erb:3:in `map'
            app/views/queries/execute.csv.erb:3:in `_render_template__652100315_2182241460_0'
            app/views/queries/execute.csv.erb:2:in `_render_template__652100315_2182241460_0'
            app/controllers/queries_controller.rb:34:in `execute'

        Rendered /rails/actionpack-3.0.0.beta/lib/action_dispatch/middleware/templates/rescues/_trace.erb (1.0ms)
        Rendered /rails/actionpack-3.0.0.beta/lib/action_dispatch/middleware/templates/rescues/_request_and_response.erb (9.7ms)
        Rendered /rails/actionpack-3.0.0.beta/lib/action_dispatch/middleware/templates/rescues/template_error.erb within /Users/willem/.rvm/gems/ruby-1.8.7-p248/gems/actionpack-3.0.0.beta/lib/action_dispatch/middleware/templates/rescues/layout.erb (20.4ms)

      EOLOG

      log_parser.should_receive(:handle_request).once
      log_parser.should_receive(:warn).exactly(3).times
      log_parser.parse_string(log)
    end
  end
end
