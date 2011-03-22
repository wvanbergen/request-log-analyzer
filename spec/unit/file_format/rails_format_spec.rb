require 'spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails do

  describe '.create' do

    context 'without providing a lines argument' do
      subject { RequestLogAnalyzer::FileFormat::Rails.create } 

      it { should be_well_formed }
      it { should have(11).report_trackers }

      it "should parse the lines in the production set" do
        subject.line_definitions.should == RequestLogAnalyzer::FileFormat.load(:rails, 'production').line_definitions
      end
    end

    context 'using a comma separated list of lines as argument' do
      subject {  RequestLogAnalyzer::FileFormat.load(:rails, 'minimal,failure') }

      it { should be_well_formed }
      it { should have(10).report_trackers }
      
      it { should have_line_definition(:processing) }
      it { should have_line_definition(:completed) }
      it { should have_line_definition(:failure) }
    end

    RequestLogAnalyzer::FileFormat::Rails::LINE_COLLECTIONS.keys.each do |constant|

      context "using the '#{constant}' line collection constant" do
        subject { RequestLogAnalyzer::FileFormat.load(:rails, constant) }

        it { should be_well_formed }
        it { should have_at_least(9).report_trackers }

        it { should have_line_definition(:processing) }
        it { should have_line_definition(:completed) }
      end
    end
  end
  
  subject { RequestLogAnalyzer::FileFormat.load(:rails, :all) }

  describe '#parse_line' do

    {'with prefix' => 'LINE PREFIX: ', 'without prefix' => '' }.each do |context, prefix|
      context context do
        it "should parse a :processing line correctly" do
          line = prefix + 'Processing PeopleController#index (for 1.1.1.1 at 2008-08-14 21:16:30) [GET]'
          subject.should parse_line(line).as(:processing).and_capture(:controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET', :ip => '1.1.1.1')
        end
        
        it "should parse a :processing line correctly when it contains ipv6 localhost address" do
           line = prefix + 'Processing PeopleController#index (for ::1 at 2008-08-14 21:16:30) [GET]'
           subject.should parse_line(line).as(:processing).and_capture(:controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET', :ip => '::1')
        end

        it "should parse a :processing line correctly when it contains ipv6 address" do
           line = prefix + 'Processing PeopleController#index (for 3ffe:1900:4545:3:200:f8ff:fe21:67cf at 2008-08-14 21:16:30) [GET]'
           subject.should parse_line(line).as(:processing).and_capture(:controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET', :ip => '3ffe:1900:4545:3:200:f8ff:fe21:67cf')
        end

        it "should parse a Rails 2.1 style :completed line correctly" do
          line = prefix + 'Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]'
          subject.should parse_line(line).as(:completed).and_capture(:duration => 0.21665, :db => 0.0, :view => 0.00926, :status => 200, :url => 'http://demo.nu/employees')
        end

        it "should parse a Rails 2.2 style :completed line correctly" do
          line = prefix + 'Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]'
          subject.should parse_line(line).as(:completed).and_capture(:duration => 0.614, :db => 0.031, :view => 0.120, :status => 200, :url => 'http://floorplanner.local/demo')
        end

        it "should parse a Rails 2.2 style :completed line correctly when AR is disabled" do
          line = prefix + 'Completed in 597ms (View: 298 | 200 OK [http://shapado.com]'
          subject.should parse_line(line).as(:completed).and_capture(:duration => 0.597, :db => nil, :view => 0.298, :status => 200, :url => 'http://shapado.com')
        end
        
        it "should parse a Rails 2.2 style :completed line without view" do
          line = prefix + "Completed in 148ms (DB: 0) | 302 Found [http://iwp-sod.hargray.org/login]"
          subject.should parse_line(line).as(:completed).and_capture(:duration => 0.148, :db => 0.0, :view => nil, :status => 302, :url => 'http://iwp-sod.hargray.org/login')
        end

        it "should parse a :failure line with exception correctly" do
          line = prefix + "NoMethodError (undefined method `update_domain_account' for nil:NilClass):"
          subject.should parse_line(line).as(:failure).and_capture(:error => 'NoMethodError', :message => "undefined method `update_domain_account' for nil:NilClass")
        end

        it "should parse a :cache_hit line correctly with an filter instance reference" do
          line = prefix + 'Filter chain halted as [#<ActionController::Filters::AroundFilter:0x2a999ad120 @identifier=nil, @kind=:filter, @options={:only=>#<Set: {"cached"}>, :if=>:not_logged_in?, :unless=>nil}, @method=#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>>] did_not_yield.'
          subject.should parse_line(line).as(:cache_hit)
        end

        it "should parse a :cache_hit line correctly with an proc instance reference" do
          line = prefix + 'Filter chain halted as [#<ActionController::Filters::AroundFilter:0x2a9a923e38 @method=#<Proc:0x0000002a9818b3f8@/usr/local/lib/ruby/gems/1.8/gems/actionpack-2.3.5/lib/action_controller/caching/actions.rb:64>, @kind=:filter, @identifier=nil, @options={:unless=>nil, :if=>nil, :only=>#<Set: {"show"}>}>] did_not_yield.'          
          subject.should parse_line(line).as(:cache_hit)
        end


        it "should parse a :parameters line correctly" do
          line = prefix + '  Parameters: {"action"=>"cached", "controller"=>"cached"}'
          subject.should parse_line(line).as(:parameters).and_capture(:params => {:action => 'cached', :controller => 'cached'})
        end

        it "should parse a :rendered line correctly" do
          line = prefix + 'Rendered layouts/_footer (2.9ms)'
          subject.should parse_line(line).as(:rendered).and_capture(:render_file => 'layouts/_footer', :render_duration => 0.0029)
        end

        it "should parse a :query_executed line with colors" do
          line = prefix + ' [4;36;1mUser Load (0.4ms)[0m   [0;1mSELECT * FROM `users` WHERE (`users`.`id` = 18205844) [0m'
          subject.should parse_line(line).as(:query_executed).and_capture(:query_class => 'User', :query_duration => 0.0004, :query_sql => 'SELECT * FROM users WHERE (users.id = :int)')
        end

        it "should parse a :query_executed line without colors" do
          line = prefix + ' User Load (0.4ms)   SELECT * FROM `users` WHERE (`users`.`id` = 18205844) '
          subject.should parse_line(line).as(:query_executed).and_capture(:query_class => 'User', :query_duration => 0.0004, :query_sql => 'SELECT * FROM users WHERE (users.id = :int)')
        end

        it "should parse a :query_cached line with colors" do
          line = prefix + ' [4;35;1mCACHE (0.0ms)[0m   [0mSELECT * FROM `users` WHERE (`users`.`id` = 0) [0m'
          subject.should parse_line(line).as(:query_cached).and_capture(:cached_duration => 0.0, :cached_sql => 'SELECT * FROM users WHERE (users.id = :int)')
        end

        it "should parse a :query_cached line without colors" do
          line = prefix + ' CACHE (0.0ms)   SELECT * FROM `users` WHERE (`users`.`id` = 0) '
          subject.should parse_line(line).as(:query_cached).and_capture(:cached_duration => 0.0, :cached_sql => 'SELECT * FROM users WHERE (users.id = :int)')
        end

        it "should not parse an unsupported line" do
          line = prefix + 'nonsense line that should not be parsed as anything'
          subject.should_not parse_line(line)
        end
      end
    end
  end

  describe '#parse_io' do
    let(:log_parser) { RequestLogAnalyzer::Source::LogParser.new(subject, :parse_strategy => 'cautious') }

    it "should parse a Rails 2.1 style log and find valid Rails requests without warnings" do
      log_parser.should_receive(:handle_request).exactly(4).times
      log_parser.should_not_receive(:warn)
      log_parser.parse_file(log_fixture(:rails_1x))\
    end

    it "should parse a Rails 2.2 style log and find valid Rails requests without warnings" do
      log_parser.should_receive(:handle_request).once
      log_parser.should_not_receive(:warn)
      log_parser.parse_file(log_fixture(:rails_22))
    end

    it "should parse a Rails SyslogLogger file with prefix and find valid requests without warnings" do
      log_parser.should_receive(:handle_request).once
      log_parser.should_not_receive(:warn)
      log_parser.parse_file(log_fixture(:syslog_1x))
    end

    it "should parse cached requests" do
      log_parser.should_not_receive(:warn)
      log_parser.parse_file(log_fixture(:rails_22_cached)) do |request|
        request.should be_completed
        request =~ :cache_hit
      end
    end

    it "should detect unordered requests in the logs" do
      log_parser.should_not_receive(:handle_request)
      log_parser.should_receive(:warn).with(:unclosed_request, anything).once
      log_parser.should_receive(:warn).with(:no_current_request, anything).at_least(:twice)
      log_parser.parse_file(log_fixture(:rails_unordered))
    end
  end
end
