# require File.dirname(__FILE__) + '/spec_helper'
# 
# describe RequestLogAnalyzer::LogParser, "Merb without combined requests" do
#   include RequestLogAnalyzerSpecHelper
#   
#   before(:each) do
#     @log_parser = RequestLogAnalyzer::LogParser.new(:merb, :combined_requests => false)
#   end
#   
#   it "should parse a stream and find valid requests" do
#     File.open(log_fixture(:merb), 'r') do |io|
#       @log_parser.parse_io(io) do |request| 
#         request.should be_kind_of(RequestLogAnalyzer::Request)
#         request.should be_single_line
#       end
#     end
#   end
# 
#   it "should find 33 request lines when lines are not linked" do
#     @log_parser.should_receive(:handle_request).exactly(33).times
#     @log_parser.parse_file(log_fixture(:merb))
#   end  
#   
#   it "should find 11 request start lines when lines are not linked" do
#     @log_parser.should_receive(:handle_request).exactly(11).times
#     @log_parser.parse_file(log_fixture(:merb), :line_types => [:started])
#   end  
# end
# 
# 
# describe RequestLogAnalyzer::LogParser, "Merb with combined requests" do
#   include RequestLogAnalyzerSpecHelper
#   
#   before(:each) do
#     @log_parser = RequestLogAnalyzer::LogParser.new(:merb, :combined_requests => true)
#   end
#   
#   it "should have a valid language definitions" do
#     @log_parser.file_format.should be_valid
#   end
#   
#   it "should find 11 completed requests when lines are linked" do
#     @log_parser.should_receive(:handle_request).exactly(11).times
#     @log_parser.parse_file(log_fixture(:merb))
#   end
#   
#   it "should parse all details from a request correctly" do
#     request = nil
#     @log_parser.parse_file(log_fixture(:merb)) { |found_request| request ||= found_request }
#     
#     request.should be_completed
#     request[:timestamp].should == DateTime.parse('Fri Aug 29 11:10:23 +0200 2008')
#     request[:dispatch_time].should == 0.243424
#     request[:after_filters_time].should == 6.9e-05
#     request[:before_filters_time].should == 0.213213
#     request[:action_time].should == 0.241652
#   end
# end