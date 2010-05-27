require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails do

  it "should be a valid file format" do
    RequestLogAnalyzer::FileFormat.load(:rails3).should be_valid
  end
  
  describe '#parse_line' do
    before(:each) { @file_format = RequestLogAnalyzer::FileFormat.load(:rails3) }

    it "should parse :started lines correctly" do
      line = 'Started GET "/queries" for 127.0.0.1 at 2010-02-25 16:15:18'
      @file_format.should parse_line(line).as(:started).and_capture(:method => 'GET', 
            :path => '/queries', :ip => '127.0.0.1', :timestamp => 20100225161518)
    end
    
    it "should parse :processing lines correctly" do
      line = ' Processing by QueriesController#index as HTML'
      @file_format.should parse_line(line).as(:processing).and_capture(
        :controller => 'QueriesController', :action => 'index', :format => 'HTML')
    end
    
    
    # it "should parse beta :completed lines correctly" do
    #   line = 'Completed in 9ms (Views: 4.9ms | ActiveRecord: 0.5ms) with 200'
    #   @file_format.should parse_line(line).as(:completed).and_capture(
    #       :duration => 0.009, :status => 200)
    # end
    
    it "should parse :completed lines correctly" do
      line = 'Completed 200 OK in 170ms (Views: 78.4ms | ActiveRecord: 48.2ms)'
      @file_format.should parse_line(line).as(:completed).and_capture(
          :duration => 0.170, :status => 200)
    end
    
    it "should pase :failure lines correctly" do
      line = "ActionView::Template::Error (undefined local variable or method `field' for #<Class>) on line #3 of /Users/willem/Code/warehouse/app/views/queries/execute.csv.erb:"
      @file_format.should parse_line(line).as(:failure).and_capture(:line => 3, 
          :error   => 'ActionView::Template::Error', 
          :message => "undefined local variable or method `field' for #<Class>", 
          :file    => '/Users/willem/Code/warehouse/app/views/queries/execute.csv.erb')
    end
  end
  
  describe '#parse_io' do
    before(:each) do
      @log_parser = RequestLogAnalyzer::Source::LogParser.new(RequestLogAnalyzer::FileFormat.load(:rails3))
    end
    
    it "should parse a successful request correctly" do
      log = <<-EOLOG
        Started GET "/" for 127.0.0.1 at 2010-03-19 06:40:41
          Processing by QueriesController#index as HTML
          SQL (16.3ms)  SHOW TABLES
          Query Load (32.0ms)  SELECT `queries`.* FROM `queries`
        Rendered queries/index.html.erb within layouts/default (40.9ms)
        Completed 200 OK in 170ms (Views: 78.4ms | ActiveRecord: 48.2ms)
      EOLOG
      
      request_counter.should_receive(:hit!).once
      @log_parser.should_not_receive(:warn)
      
      @log_parser.parse_io(StringIO.new(log)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails3::Request) && request.completed?
      end
    end
    
    it "should parse an unroutable request correctly" do
      log = <<-EOLOG
        Started GET "/404" for 127.0.0.1 at 2010-03-19 06:40:57

        ActionController::RoutingError (No route matches "/404"):


        Rendered /Users/rails/actionpack/lib/action_dispatch/middleware/templates/rescues/routing_error.erb within rescues/layout (1.0ms)
      
      EOLOG

      request_counter.should_receive(:hit!).once
      @log_parser.should_not_receive(:warn)
      
      @log_parser.parse_io(StringIO.new(log)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails3::Request) && request.completed?
      end
    end
    
    it "should parse a failing request correctly" do
      log = <<-EOLOG
        Started POST "/queries/397638749/execute.csv" for 127.0.0.1 at 2010-03-01 18:44:33
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

      request_counter.should_receive(:hit!).once
      @log_parser.should_not_receive(:warn)
      
      @log_parser.parse_io(StringIO.new(log)) do |request|
        request_counter.hit! if request.kind_of?(RequestLogAnalyzer::FileFormat::Rails3::Request) && request.completed?
      end
    end
  end
end