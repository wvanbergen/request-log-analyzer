require 'date'
require 'other/ordered_hash'

# RequestLogAnalyzer is the base namespace in which all functionality of RequestLogAnalyzer is implemented.
# This module itselfs contains some functions to help with class and source file loading. The actual 
# application startup code resides in the {RequestLogAnalyzer::Controller} class.
#
# The {RequestLogAnalyzer::VERSION} constant can be used to determine what version of request-log-analyzer
# is running.
module RequestLogAnalyzer
  
  # The current version of request-log-analyzer.
  # Do not change the value by hand; it will be updated automatically by the gem release script.
  VERSION = "1.12.7"

  # Convert a string/symbol in camelcase ({RequestLogAnalyzer::Controller}) to underscores 
  # (<tt>request_log_analyzer/controller</tt>). This function can be used to load the file (using 
  # <tt>require</tt>) in which the given constant is defined.
  #
  # @param [#to_s] str The string-like to convert in the following format: <tt>ModuleName::ClassName</tt>.
  # @return [String] The input string converted to underscore form.
  def self.to_underscore(str)
    str.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end

  # Convert a string/symbol in underscores (<tt>request_log_analyzer/controller</tt>) to camelcase
  # ({RequestLogAnalyzer::Controller}). This can be used to find the class that is defined in a given 
  # filename.
  #
  # @param [#to_s] str The string-like to convert in the f`ollowing format: <tt>module_name/class_name</tt>.
  # @return [String] The input string converted to camelcase form.  
  def self.to_camelcase(str)
    str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
end

require 'request_log_analyzer/controller'
require 'request_log_analyzer/aggregator'
require 'request_log_analyzer/file_format'
require 'request_log_analyzer/filter'
require 'request_log_analyzer/line_definition'
require 'request_log_analyzer/log_processor'
require 'request_log_analyzer/mailer'
require 'request_log_analyzer/output'
require 'request_log_analyzer/request'
require 'request_log_analyzer/source'
require 'request_log_analyzer/tracker'
