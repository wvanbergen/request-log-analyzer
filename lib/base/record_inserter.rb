require 'rubygems'
require 'sqlite3'

module Base
  
  # Set of functions that can be used to easily log requests into a SQLite3 Database.
  class RecordInserter
    
    attr_reader :database
    attr_reader :current_request
    attr_reader :warning_count
    
    # Initializer
    # <tt>db_file</tt> The file which will be used for the SQLite3 Database storage.
    def initialize(db_file, options = {})
      @database = SQLite3::Database.new(db_file)
      @insert_statements = nil
      @warning_count = 0
      create_tables_if_needed!

      self.initialize_hook(options) if self.respond_to?(:initialize_hook)
    end
        
    # Calculate the database durations of the requests currenty in the database.
    # Used if a logfile does contain any database durations.
    def calculate_db_durations!
      @database.execute('UPDATE "completed_queries" SET "database" = "duration" - "rendering" WHERE "database" IS NULL OR "database" = 0.0')
    end
    
    # Insert a batch of loglines into the database.
    # Function prepares insert statements, yeilds and then closes and commits.
    def insert_batch(&block)
      @database.transaction
      prepare_statements!
      block.call(self)
      close_prepared_statements!
      @database.commit
    rescue Exception => e
      puts e.message
      @database.rollback
    end
    
    def insert_warning(line, warning)
      @database.execute("INSERT INTO parse_warnings (line, warning) VALUES (:line, :warning)", :line => line, :warning => warning)
      @warning_count += 1
    end
        
    # Insert a request into the database.
    # def insert(request, close_statements = false)
    #   raise 'No insert defined for this log file type'
    # end
    
    # Insert a batch of files into the database.
    # <tt>db_file</tt> The filename of the database file to use.
    # Returns the created database.
    def self.insert_batch_into(db_file, options = {}, &block)
      db = self.new(db_file)
      db.insert_batch(&block)
      return db
    end    
    
    def count(type)
      @database.get_first_value("SELECT COUNT(*) FROM \"#{type}_requests\"").to_i
    end
        
    protected
    
    # Prepare insert statements.
    def prepare_statements!
      @insert_statements = {
        :started => @database.prepare("
            INSERT INTO started_requests ( line,  timestamp,  ip,  method,  controller,  action) 
                                  VALUES (:line, :timestamp, :ip, :method, :controller, :action)"),
                                  
        :failed => @database.prepare("
            INSERT INTO failed_requests ( line,  exception_string,  stack_trace,  error)
                                 VALUES (:line, :exception_string, :stack_trace, :error)"),
                                 
        :completed => @database.prepare("
            INSERT INTO completed_requests ( line,  url,  status,  duration,  rendering_time,  database_time)
                                    VALUES (:line, :url, :status, :duration, :rendering, :db)")
      }
    end
    
    # Close all prepared statments
    def close_prepared_statements!
      @insert_statements.each { |key, stmt| stmt.close }
    end

    # Create the needed database tables if they don't exist.
    def create_tables_if_needed!
      
      @database.execute("
        CREATE TABLE IF NOT EXISTS started_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          line INTEGER NOT NULL,
          timestamp DATETIME NOT NULL, 
          controller VARCHAR(255) NOT NULL, 
          action VARCHAR(255) NOT NULL,
          method VARCHAR(6) NOT NULL,          
          ip VARCHAR(6) NOT NULL
        )
      ");

      @database.execute("
          CREATE TABLE IF NOT EXISTS failed_requests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            line INTEGER NOT NULL,            
            started_request_id INTEGER,        
            error VARCHAR(255),    
            exception_string VARCHAR(255),
            stack_trace TEXT
          )      
      ");

      @database.execute("
        CREATE TABLE IF NOT EXISTS completed_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          line INTEGER NOT NULL,          
          started_request_id INTEGER,
          url VARCHAR(255) NOT NULL,
          hashed_url VARCHAR(255),
          status INTEGER NOT NULL,
          duration FLOAT,
          rendering_time FLOAT,
          database_time FLOAT
        )
      ");    
      
      @database.execute("CREATE TABLE IF NOT EXISTS parse_warnings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          line INTEGER NOT NULL,       
          warning VARCHAR(255) NOT NULL
        )
      ");
    end

  end
end