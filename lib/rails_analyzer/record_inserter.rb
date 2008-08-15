require 'rubygems'
require 'sqlite3'

module RailsAnalyzer
  
  class RecordInserter
    
    attr_reader :database
    
    def initialize(db_file)
      @database = SQLite3::Database.new(db_file)
      @insert_statements = nil
      create_tables_if_needed!
    end
    
    def self.insert_batch_into(db_file, &block)
      db = RecordInserter.new(db_file)
      db.insert_batch(&block)
      return db
    end
    
    def calculate_db_durations!
      @database.execute('UPDATE "completed_queries" SET "database" = "duration" - "rendering" WHERE "database" IS NULL OR "database" = 0.0')
    end
    
    def insert_batch(&block)
      @database.transaction
      prepare_statements!
      yield(self)
      close_prepared_statements!
      @database.commit
    rescue
      @database.rollback
    end
        
    def insert(request, close_statements = false)
      if @insert_statements.nil?
        prepare_statements! 
        close_statements = true
      end
        
      if request[:type] && @insert_statements.has_key?(request[:type]) 
        @insert_statements[request.delete(:type)].execute(request)
      else
        puts "Ignored unknown statement type"
      end
      
      close_prepared_statements! if close_statements
    end
    
    protected
    
    def prepare_statements!
      @insert_statements = {
        :started => @database.prepare("
            INSERT INTO started_requests ( timestamp,  ip,  method,  controller,  action) 
                                  VALUES (:timestamp, :ip, :method, :controller, :action)"),
        :completed => @database.prepare("
            INSERT INTO completed_requests ( url,  status,  duration,  rendering,  db)
                                    VALUES (:url, :status, :duration, :rendering, :db)")
      }
    end
    
    def close_prepared_statements!
      @insert_statements.each { |key, stmt| stmt.close }
    end

    def create_tables_if_needed!
      @database.execute("
        CREATE TABLE IF NOT EXISTS started_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          timestamp DATETIME NOT NULL, 
          controller VARCHAR(255) NOT NULL, 
          action VARCHAR(255) NOT NULL,
          method VARCHAR(6) NOT NULL,          
          ip VARCHAR(6) NOT NULL,          
          completed_request_id INTEGER
        )
      ");

      @database.execute("
        CREATE TABLE IF NOT EXISTS completed_requests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url VARCHAR(255) NOT NULL,
          hashed_url VARCHAR(255),
          status INTEGER NOT NULL,
          duration FLOAT,
          rendering FLOAT,
          db FLOAT
        )
      ");    
    end
    
  end
end