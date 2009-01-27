module RequestLogAnalyzer::Spec::Mocks
  
  def mock_source
    source = mock('RequestLogAnalyzer::Source::Base')
    source.stub!(:file_format).and_return(testing_format)
    source.stub!(:parsed_requests).and_return(2)
    source.stub!(:skipped_requests).and_return(1)    
    source.stub!(:parse_lines).and_return(10)
    
    source.stub!(:warning=)
    source.stub!(:progress=)

    source.stub!(:prepare)
    source.stub!(:finalize)
        
    source.stub!(:each_request).and_return do |block|
      block.call(testing_format.request(:field => 'value1'))
      block.call(testing_format.request(:field => 'value2'))
    end
    
    return source
  end

  def mock_io
    mio = mock('IO')
    mio.stub!(:print)
    mio.stub!(:puts)    
    mio.stub!(:write)
    return mio
  end
  
  def mock_output
    output = mock('RequestLogAnalyzer::Output::Base')
    output.stub!(:header)
    output.stub!(:footer)   
    output.stub!(:puts)
    output.stub!(:<<)    
    output.stub!(:title)
    output.stub!(:line)
    output.stub!(:with_style)    
    output.stub!(:table) { yield [] }
    output.stub!(:io).and_return(mock_io)
    return output
  end
  
  
end