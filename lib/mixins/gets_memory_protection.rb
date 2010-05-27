class File
  alias_method :gets_original, :gets
  # The size of the reads we will use to add to the line buffer.
  MAX_READ_SIZE=1024*100

  # 
  # This method returns the next line of the File.
  # 
  # It works by moving the file pointer forward +MAX_READ_SIZE+ at a time, 
  # storing seen lines in <tt>@line_buffer</tt>.  Once the buffer contains at 
  # least two lines (ensuring we have seen on full line) or the file pointer 
  # reaches the end of the File, the last line from the buffer is returned.  
  # When the buffer is exhausted, this will throw +nil+ (from the empty Array).
  #
  # Read portions of the file that do not contain the +sep_string+ are not added to 
  # the buffer. This prevents <tt>@line_buffer<tt> from growing signficantly when parsing
  # large lines.
  #
  def gets(sep_string = $/)
    @read_size ||= MAX_READ_SIZE
    # A buffer to hold lines read, but not yet returned.
    @line_buffer ||= Array.new
        
    # Record where we are.
    @current_pos ||= pos
    
    # Last Position in the file
    @last_pos ||= nil
    if @last_pos.nil? 
      seek(0, IO::SEEK_END)
      @last_pos = pos
      seek(0,0)
    end
    
    # 
    # If we have more than one line in the buffer or we have reached the
    # beginning of the file, send the last line in the buffer to the caller.  
    # (This may be +nil+, if the buffer has been exhausted.)
    #
    if @line_buffer.size > 2 or @current_pos >= @last_pos
      self.lineno += 1
      return @line_buffer.shift 
    end
    
    sep = 
    
    chunk = String.new
    while chunk and chunk !~ /#{sep_string}/   
      chunk = read(@read_size)
    end
    
    # Appends new lines to the last element of the buffer
    line_buffer_pos = @line_buffer.any? ? @line_buffer.size-1 : 0
    
    if chunk
      @line_buffer[line_buffer_pos] = @line_buffer[line_buffer_pos].to_s<< chunk
    else
      # at the end
      return @line_buffer.shift
    end
    
    # 
    # Divide the last line of the buffer based on +sep_string+ and #flatten!
    # those new lines into the buffer.
    # 
    @line_buffer[line_buffer_pos] = @line_buffer[line_buffer_pos].scan(/.*?#{Regexp.escape(sep_string)}|.+/)
    @line_buffer.flatten!

    # 
    # If we made it this far, we need to read more data to try and find the 
    # end of a line or the end of the file.  Move the file pointer
    # forward a step, to give us new bytes to read.
    #
    @current_pos += @read_size
    seek(@current_pos, IO::SEEK_SET)
    
    # We have more data now, so try again to read a line...
    gets(sep_string)
  end
end