require 'date'

# Satisfy ruby 1.9 sensitivity about encoding.
Encoding.default_external = 'binary' if defined? Encoding and Encoding.respond_to? 'default_external='

# RequestLogAnalyzer is the base namespace in which all functionality of RequestLogAnalyzer is implemented.
#
# - This module itselfs contains some functions to help with class and source file loading.
# - The actual application resides in the RequestLogAnalyzer::Controller class.
module RequestLogAnalyzer
  
  # The current version of request-log-analyzer.
  # This will be diplayed in output reports etc.  
  VERSION = "1.2.7"
  
  # Loads constants in the RequestLogAnalyzer namespace using self.load_default_class_file(base, const)
  # <tt>const</tt>:: The constant that is not yet loaded in the RequestLogAnalyzer namespace. This should be passed as a string or symbol.
  def self.const_missing(const)
    load_default_class_file(RequestLogAnalyzer, const)
  end
    
  # Loads constants that reside in the RequestLogAnalyzer tree using the constant name
  # and its base constant to determine the filename.
  # <tt>base</tt>:: The base constant to load the constant from. This should be Foo when the constant Foo::Bar is being loaded.
  # <tt>const</tt>:: The constant to load from the base constant as a string or symbol. This should be 'Bar' or :Bar when the constant Foo::Bar is being loaded.
  def self.load_default_class_file(base, const)
    path     = to_underscore(base.to_s)
    basename = to_underscore(const.to_s)
    filename = "#{File.dirname(__FILE__)}/#{path}/#{basename}"
    require filename
    base.const_get(const)
  end

  # Convert a string/symbol in camelcase (RequestLogAnalyzer::Controller) to underscores (request_log_analyzer/controller)
  # This function can be used to load the file (using require) in which the given constant is defined.
  # <tt>str</tt>:: The string to convert in the following format: <tt>ModuleName::ClassName</tt>
  def self.to_underscore(str)
    str.to_s.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase
  end  

  # Convert a string/symbol in underscores (<tt>request_log_analyzer/controller</tt>) to camelcase 
  # (<tt>RequestLogAnalyzer::Controller</tt>). This can be used to find the class that is defined in a given filename.
  # <tt>str</tt>:: The string to convert in the following format: <tt>module_name/class_name</tt>
  def self.to_camelcase(str)
    str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
end
