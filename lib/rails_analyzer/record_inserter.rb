require 'rubygems'
require 'sqlite3'

module RailsAnalyzer
  
  # Set of functions that can be used to easily log requests into a SQLite3 Database.
  class RecordInserter < Base::RecordInserter
    
    # Insert a request into the database.
    # <tt>request</tt> The request to insert.
    # <tt>close_statements</tt> Close prepared statements (default false)
    def insert(request, close_statements = false)
      unless @insert_statements
        prepare_statements! 
        close_statements = true
      end
        
      if request[:type] && @insert_statements.has_key?(request[:type]) 
        if request[:type] == :started
          insert_warning(request[:line], "Unclosed request encountered on line #{request[:line]} (request started on line #{@current_request})") unless @current_request.nil?
          @current_request = request[:line]
        elsif [:failed, :completed].include?(request[:type])
          @current_request = nil
        end
        
        begin
          @insert_statements[request.delete(:type)].execute(request) 
        rescue SQLite3::Exception => e
          insert_warning(request[:line], "Could not save log line to database: " + e.message.to_s)
        end        
      else
        insert_warning(request[:line], "Ignored unknown statement type")
      end
      
      close_prepared_statements! if close_statements
    end
    
  end
end