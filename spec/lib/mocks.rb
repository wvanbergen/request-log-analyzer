module RequestLogAnalyzer::RSpec::Mocks

  def mock_source
    source = mock('RequestLogAnalyzer::Source::Base')
    source.stub!(:file_format).and_return(testing_format)
    source.stub!(:parsed_requests).and_return(2)
    source.stub!(:skipped_requests).and_return(1)
    source.stub!(:parse_lines).and_return(10)

    source.stub!(:warning=)
    source.stub!(:progress=)
    source.stub!(:source_changes=)

    source.stub!(:prepare)
    source.stub!(:finalize)

    source.stub!(:each_request).
      and_yield(testing_format.request(:field => 'value1')).
      and_yield(testing_format.request(:field => 'value2'))

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
    output.stub!(:report_tracker)
    output.stub!(:header)
    output.stub!(:footer)
    output.stub!(:puts)
    output.stub!(:<<)
    output.stub!(:colorize).and_return("Fancy text")
    output.stub!(:link)
    output.stub!(:title)
    output.stub!(:line)
    output.stub!(:with_style)
    output.stub!(:table).and_yield([])
    output.stub!(:io).and_return(mock_io)
    output.stub!(:options).and_return({})
    output.stub!(:slice_results).and_return { |a| a } 
    return output
  end

  def mock_database(*stubs)
    database = mock('RequestLogAnalyzer::Database')
    database.stub!(:connect)
    database.stub!(:disconnect)
    database.stub!(:connection).and_return(mock_connection)
    stubs.each { |s| database.stub!(s)}
    return database
  end

  def mock_connection
    table_creator = mock('ActiveRecord table creator')
    table_creator.stub!(:column)

    connection = mock('ActiveRecord::Base.connection')
    connection.stub!(:add_index)
    connection.stub!(:remove_index)
    connection.stub!(:table_exists?).and_return(false)
    connection.stub!(:create_table).and_yield(table_creator).and_return(true)
    connection.stub!(:table_creator).and_return(table_creator)
    return connection
  end
end
