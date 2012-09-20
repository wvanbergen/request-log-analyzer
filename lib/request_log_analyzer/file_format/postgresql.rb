module RequestLogAnalyzer::FileFormat

  # PostgresQL spec 8.3.7
  class Postgresql < Base

    extend CommonRegularExpressions
    
    line_definition :query do |line|
      line.header = true
      line.teaser = /.*LOG\:/
      line.regexp = /(#{timestamp('%Y-%m-%d %k:%M:%S')})\ \S+ \[\d+\]\:\ \[.*\]\ LOG\:\ \ \d+\:\ duration\: (.*)\ ms\ \ statement:\ (.*)/

      line.capture(:timestamp).as(:timestamp)
      line.capture(:query_time).as(:duration, :unit => :sec)
      line.capture(:query_fragment)
    end
      
    line_definition :location do |line|
      line.footer = true
      line.teaser = /.*LOCATION:/
      line.regexp = /.*(\ )LOCATION:/

      line.capture(:query).as(:sql) # Hack to gather up fragments
    end
    
    line_definition :query_fragment do |line|
      line.regexp = /^(?!.*LOG)\s*(.*)\s*/
      line.capture(:query_fragment)
    end

    report do |analyze|
      analyze.timespan
      analyze.hourly_spread      
      analyze.duration :query_time, :category => :query, :title => 'Query time'
    end
  
    class Request < RequestLogAnalyzer::Request

      def convert_sql(value, definition)
        
        # Recreate the full SQL query by joining all the previous parts and this last line
        sql = every(:query_fragment).join("\n") + value

        # Sanitize an SQL query so that it can be used as a category field.
        # sql.gsub!(/\/\*.*\*\//, '')                                       # remove comments
        sql.gsub!(/\s+/, ' ')                                             # remove excessive whitespace
        sql.gsub!(/"([^"]+)"/, '\1')                                      # remove quotes from field names
        sql.gsub!(/'\d{4}-\d{2}-\d{2}'/, ':date')                         # replace dates
        sql.gsub!(/'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'/, ':datetime')   # replace timestamps
        sql.gsub!(/'[^']*'/, ':string')                                   # replace strings
        sql.gsub!(/\b\d+\b/, ':int')                                      # replace integers
        sql.gsub!(/(:int,)+:int/, ':ints')                                # replace multiple ints by a list
        sql.gsub!(/(:string,)+:string/, ':strings')                       # replace multiple strings by a list

        return sql.lstrip.rstrip
      end

      def host
        self[:host] == '' || self[:host].nil? ? self[:ip] : self[:host]
      end

      # Convert the timestamp to an integer
      def convert_timestamp(value, definition)
        _, y, m, d, h, i, s = value.split(/(\d\d)-(\d\d)-(\d\d)\s+(\d?\d):(\d\d):(\d\d)/)
        ('20%s%s%s%s%s%s' % [y,m,d,h.rjust(2, '0'),i,s]).to_i
      end
    end
  end
end
