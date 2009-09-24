require File.dirname(__FILE__) + '/../../spec_helper'

describe RequestLogAnalyzer::FileFormat::Rails do

  describe '.create' do

    context 'without providing a lines argument' do
      before(:each) { @rails = RequestLogAnalyzer::FileFormat.load(:rails) }

      it "should create a valid file format" do
        @rails.should be_valid
      end

      it "should parse the production lines" do
        production_rails = RequestLogAnalyzer::FileFormat.load(:rails, 'production')
        @rails.line_definitions.should == production_rails.line_definitions
      end
    end

    context 'using a comma separated list of lines as argument' do
      before(:each) { @rails = RequestLogAnalyzer::FileFormat.load(:rails, 'minimal,failure') }

      it "should return a valid language" do
        @rails.should be_valid
      end
      
      it "should at least parse :processing and :completed lines" do
        @rails.line_definitions.should include(:processing, :completed, :failure)
      end      
    end

    RequestLogAnalyzer::FileFormat::Rails::LINE_COLLECTIONS.keys.each do |constant|
      context "using the '#{constant}' line collection constant" do

        before(:each) { @rails = RequestLogAnalyzer::FileFormat.load(:rails, constant) }

        it "should return a valid language" do
          @rails.should be_valid
        end

        it "should at least parse :processing and :completed lines" do
          @rails.line_definitions.should include(:processing, :completed)
        end
      end
    end
  end

  describe '#parse_line' do
    before(:each) do
      @rails   = RequestLogAnalyzer::FileFormat.load(:rails, :all)
    end
    
    sample_lines = [
      [:processing, nil, 
          'Processing PeopleController#index (for 1.1.1.1 at 2008-08-14 21:16:30) [GET]',
          { :controller => 'PeopleController', :action => 'index', :timestamp => 20080814211630, :method => 'GET'}],
      [:completed, 'Rails 2.1 style',
          'Completed in 0.21665 (4 reqs/sec) | Rendering: 0.00926 (4%) | DB: 0.00000 (0%) | 200 OK [http://demo.nu/employees]',
          {:duration => 0.21665, :db => 0.0, :view => 0.00926, :status => 200, :url => 'http://demo.nu/employees'}],
      [:completed, 'Rails 2.2 style', 
        'Completed in 614ms (View: 120, DB: 31) | 200 OK [http://floorplanner.local/demo]',
          {:duration => 0.614, :db => 0.031, :view => 0.120, :status => 200, :url => 'http://floorplanner.local/demo'}],
      [:failure, nil,
          "NoMethodError (undefined method `update_domain_account' for nil:NilClass):",
          {:error => 'NoMethodError', :message => "undefined method `update_domain_account' for nil:NilClass"} ],
      [:cache_hit, nil, 
          'Filter chain halted as [#<ActionController::Caching::Actions::ActionCacheFilter:0x2a999ad620 @check=nil, @options={:store_options=>{}, :layout=>nil, :cache_path=>#<Proc:0x0000002a999b8890@/app/controllers/cached_controller.rb:8>}>] rendered_or_redirected.'],
      [:parameters, nil,
          '  Parameters: {"action"=>"cached", "controller"=>"cached"}', 
          {:params => {:action => 'cached', :controller => 'cached'}}],
      [:rendered, nil, 
          'Rendered layouts/_footer (2.9ms)', 
          {:render_file => 'layouts/_footer', :render_duration => 0.0029} ],
      [:query_executed, 'with coloring', 
          ' [4;36;1mUser Load (0.4ms)[0m   [0;1mSELECT * FROM `users` WHERE (`users`.`id` = 18205844) [0m',
          {:query_class => 'User', :query_duration => 0.0004, :query_sql => 'SELECT * FROM users WHERE (users.id = :int)' }],
      [:query_executed, 'without coloring', 
          ' User Load (0.4ms)   SELECT * FROM `users` WHERE (`users`.`id` = 18205844) ',
          {:query_class => 'User', :query_duration => 0.0004, :query_sql => 'SELECT * FROM users WHERE (users.id = :int)' }],
      [:query_cached, 'with coloring',   
          ' [4;35;1mCACHE (0.0ms)[0m   [0mSELECT * FROM `users` WHERE (`users`.`id` = 0) [0m',
          {:cached_duration => 0.0, :cached_sql => 'SELECT * FROM users WHERE (users.id = :int)' }],
      [:query_cached, 'without coloring',
          ' CACHE (0.0ms)   SELECT * FROM `users` WHERE (`users`.`id` = 0) ',
          {:cached_duration => 0.0, :cached_sql => 'SELECT * FROM users WHERE (users.id = :int)' }],
    ]
    
    sample_lines.each do |(line_type, comment, sample, values)|
      values   ||= {}
      definition = RequestLogAnalyzer::FileFormat::Rails::LINE_DEFINITIONS[line_type]
      
      context "with a #{line_type.inspect} line #{comment}" do
        before(:each) { @parse_result = @rails.parse_line(sample) }
        
        it "should recognize the line" do
          @parse_result.should be_kind_of(Hash)
        end
        
        it "should recognize the line type correctly" do
          @parse_result[:line_definition].should == definition
        end
        
        it "should capture #{definition.captures.length} values" do
          @parse_result[:captures].should have(definition.captures.length).items
        end
        
        values.each do |key, value|
          it "should capture the #{key.inspect} value correctly as #{value.inspect}" do
            @rails.request(@parse_result)[key].should == value
          end
        end
      end
    end

    it "should return nil with an unsupported line" do
      @rails.parse_line('nonsense').should be_nil
    end
  end

  before(:each) do
    @log_parser = RequestLogAnalyzer::Source::LogParser.new(
          RequestLogAnalyzer::FileFormat.load(:rails), :parse_strategy => 'cautious')
  end

  it "should have a valid language definitions" do
    @log_parser.file_format.should be_valid
  end

  it "should parse a stream and find valid requests" do
    io = File.new(log_fixture(:rails_1x), 'r')
    @log_parser.parse_io(io) do |request|
      request.should be_kind_of(RequestLogAnalyzer::Request)
    end
    io.close
  end

  it "should find 4 completed requests" do
    @log_parser.should_not_receive(:warn)
    @log_parser.should_receive(:handle_request).exactly(4).times
    @log_parser.parse_file(log_fixture(:rails_1x))
  end

  it "should parse a Rails 2.2 request properly" do
    @log_parser.should_not_receive(:warn)
    @log_parser.parse_file(log_fixture(:rails_22)) do |request|
      request.should =~ :processing
      request.should =~ :completed
    end
  end

  it "should parse a syslog file with prefix correctly" do
    @log_parser.should_not_receive(:warn)
    @log_parser.parse_file(log_fixture(:syslog_1x)) do |request|
      request.should be_completed
    end
  end

  it "should parse cached requests" do
    @log_parser.should_not_receive(:warn)
    @log_parser.parse_file(log_fixture(:rails_22_cached)) do |request|
      request.should be_completed
      request =~ :cache_hit
    end
  end

  it "should detect unordered requests in the logs" do
    # No valid request should be found in cautious mode
    @log_parser.should_not_receive(:handle_request)
    # the first Processing-line will not give a warning, but the next one will
    @log_parser.should_receive(:warn).with(:unclosed_request, anything).once
    # Both Completed lines will give a warning
    @log_parser.should_receive(:warn).with(:no_current_request, anything).twice

    @log_parser.parse_file(log_fixture(:rails_unordered))
  end
end
