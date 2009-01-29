require 'date'
require File.dirname(__FILE__) + '/cli/progressbar'

module RequestLogAnalyzer
   
  VERSION = '1.1'
  
  def self.const_missing(const)
    load_default_class_file(RequestLogAnalyzer, const)
  end
    
  # Function to implement 
  def self.load_default_class_file(base, const)
    path     = to_underscore(base.to_s)
    basename = to_underscore(const.to_s)
    filename = "#{File.dirname(__FILE__)}/#{path}/#{basename}"
    require filename
    base.const_get(const)
  end

  # Convert a string/symbol in camelcase (RequestLogAnalyzer::Controller) to underscores (request_log_analyzer/controller)
  def self.to_underscore(str)
    str.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end  

  # Convert a string/symbol in underscores (request_log_analyzer/controller) to camelcase (RequestLogAnalyzer::Controller)    
  def self.to_camelcase(str)
    str.to_s.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
end


