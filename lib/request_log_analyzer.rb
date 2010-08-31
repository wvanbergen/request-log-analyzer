require 'date'

# Satisfy ruby 1.9 sensitivity about encoding.
Encoding.default_external = 'binary' if defined? Encoding and Encoding.respond_to? 'default_external='

# RequestLogAnalyzer is the base namespace in which all functionality of RequestLogAnalyzer is implemented.
# This module itselfs contains some functions to help with class and source file loading. The actual 
# application startup code resides in the {RequestLogAnalyzer::Controller} class.
#
# The {RequestLogAnalyzer::VERSION} constant can be used to determine what version of request-log-analyzer
# is running.
module RequestLogAnalyzer

  # The current version of request-log-analyzer.
  # Do not change the value by hand; it will be updated automatically by the gem release script.
  VERSION = "1.8.0"

  # Loads constants in the RequestLogAnalyzer namespace using self.load_default_class_file(base, const)
  # @param [Symbol] const The constant that is not yet loaded in the RequestLogAnalyzer namespace. This 
  #        should  be passed as a string or symbol.
  # @return [Module] The loaded module, nil if it was not found on the expected location.
  def self.const_missing(const)
    load_default_class_file(RequestLogAnalyzer, const)
  end

  # Loads constants that reside in the RequestLogAnalyzer tree using the constant name and its base 
  # constant to determine the filename.
  # @param [Module] base The base constant to load the constant from. This should be <tt>Foo</tt> when
  #        the constant <tt>Foo::Bar</tt> is being loaded.
  # @param [Symbol] const The constant to load from the base constant as a string or symbol. This 
  #        should be <tt>"Bar"<tt> or <tt>:Bar</tt> when the constant <tt>Foo::Bar</tt> is being loaded.
  # @return [Module] The loaded module, nil if it was not found on the expected location.
  def self.load_default_class_file(base, const)
    require "#{to_underscore("#{base.name}::#{const}")}"
    base.const_get(const) if base.const_defined?(const)
  end

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
  # @param [#to_s] str The string-like to convert in the following format: <tt>module_name/class_name</tt>.
  # @return [String] The input string converted to camelcase form.  
  def self.to_camelcase(str)
    str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
  end
end
