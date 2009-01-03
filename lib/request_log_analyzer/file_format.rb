module RequestLogAnalyzer
  
  class FileFormat
    
    # Makes classes aware of a file format by registering the file_format variable
    module Awareness
      
      def self.included(base)
        base.send(:attr_reader, :file_format)
      end
      
      def register_file_format(format)
        @file_format = format
      end
    end
      
    def self.inherited(subclass)
       subclass.instance_variable_set(:@line_definer, RequestLogAnalyzer::LineDefinition::Definer.new)
       subclass.class_eval { class << self; attr_accessor :line_definer; end } 
       subclass.class_eval { class << self; attr_accessor :report_definer; end }       
    end    
    
    def self.line_definition(name, &block)
      @line_definer.send(name, &block)
    end
    
    def self.format_definition(&block)
      if block_given?
        yield(@line_definer) 
      else
        return @line_definer
      end
    end
    
    def self.report(&block)
      @report_definer = RequestLogAnalyzer::Aggregator::Summarizer::Definer.new
      yield(@report_definer)
    end

    def self.load(file_format)
      if file_format.kind_of?(RequestLogAnalyzer::FileFormat)
        # this already is a file format! return itself
        return file_format

      elsif file_format.kind_of?(Class) && file_format.ancestors.include?(RequestLogAnalyzer::FileFormat)
        klass = file_format

      elsif file_format.kind_of?(String) && File.exist?(file_format)
        # load a format from a ruby file
        require file_format
        klass_name = File.basename(file_format, '.rb').split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')
        klass = Object.const_get(klass_name)

      elsif File.exist?("#{File.dirname(__FILE__)}/file_format/#{file_format}.rb")
        # load a provided file format
        require "#{File.dirname(__FILE__)}/file_format/#{file_format}"
        klass_name = file_format.to_s.split(/[^a-z0-9]/i).map{ |w| w.capitalize }.join('')
        klass = RequestLogAnalyzer::FileFormat.const_get(klass_name)
        
      end
      
      klass.new # return an instance of the class
    end
    
    def line_definitions
      @line_definitions ||= self.class.line_definer.line_definitions
    end
    
    def report_definer
      self.class.instance_variable_get(:@report_definer)
    end
    
    def valid?
      line_definitions.detect { |(name, ld)| ld.header } && line_definitions.detect { |(name, ld)| ld.footer }
    end
  end
end