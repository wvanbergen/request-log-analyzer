$: << File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'
require 'request_log_analyzer'

module RequestLogAnalyzer::Spec; end

require File.dirname(__FILE__) + '/lib/testing_format'
require File.dirname(__FILE__) + '/lib/mocks'
require File.dirname(__FILE__) + '/lib/helper'
