module RequestLogAnalyzer::FileFormat

  class Mysql < Base

    extend CommonRegularExpressions

    line_definition :time do |line|
      line.header = :alternative
      line.teaser = /\# Time: /
      line.regexp = /\# Time: (#{timestamp('%y%m%d %k:%M:%S')})/
      
      line.capture(:timestamp).as(:timestamp)
    end

    line_definition :user_host do |line|
      line.header = :alternative
      line.teaser = /\# User\@Host\: /
      line.regexp = /\# User\@Host\: ([\w-]+)\[[\w-]+\] \@ (#{hostname(true)}) \[(#{ip_address(true)})\]/
      
      line.capture(:user)
      line.capture(:host)
      line.capture(:ip)
    end

    line_definition :query_statistics do |line|
      line.header = :alternative
      line.teaser = /\# Query_time: /
      line.regexp = /\# Query_time: (\d+(?:\.\d+)?)\s+Lock_time: (\d+(?:\.\d+)?)\s+Rows_sent: (\d+)\s+Rows_examined: (\d+)/
      
      line.capture(:query_time).as(:duration, :unit => :sec)
      line.capture(:lock_time).as(:duration, :unit => :sec)
      line.capture(:rows_sent).as(:integer)
      line.capture(:rows_examined).as(:integer)
    end

    line_definition :use_database do |line|
      line.regexp   = /^\s*use (\w+);\s*$/
      line.capture(:database)
    end

    line_definition :query_part do |line|
      line.regexp   = /^\s*(?!(?:use |\# |SET ))(.*[^;\s])\s*$/
      line.capture(:query_fragment)
    end

    line_definition :query do |line|
      line.footer = true
      line.regexp = /^(?!\s*(?:use |\# |SET ))(.*);\s*$/
      line.capture(:query).as(:sql)
    end

    PER_USER       = :user
    PER_QUERY      = :query
    PER_USER_QUERY = Proc.new { |request| "#{request[:user]}@#{request.host}: #{request[:query]}" }

    report do |analyze|
      analyze.timespan :line_type => :time
      analyze.frequency :user, :title => "Users with most queries"
      analyze.duration :query_time, :category => PER_USER, :title => 'Query time per user'
      analyze.duration :query_time, :category => PER_USER_QUERY, :title => 'Query time'
      
      analyze.duration :lock_time,  :category => PER_USER_QUERY, :title => 'Lock time',
                       :if => lambda { |request| request[:lock_time] > 0.0 }
      
      analyze.numeric_value :rows_examined, :category => PER_USER_QUERY, :title => "Rows examined"
      analyze.numeric_value :rows_sent,     :category => PER_USER_QUERY, :title => "Rows sent"
    end
  
    class Request < RequestLogAnalyzer::Request

      def convert_sql(value, definition)

        # Recreate the full SQL query by joining all the previous parts and this last line
        sql = every(:query_fragment).join("\n") + value

        # Sanitize an SQL query so that it can be used as a category field.
        # sql.gsub!(/\/\*.*\*\//, '')                                       # remove comments
        sql.gsub!(/\s+/, ' ')                                             # remove excessive whitespace
        sql.gsub!(/`([^`]+)`/, '\1')                                      # remove quotes from field names
        sql.gsub!(/'\d{4}-\d{2}-\d{2}'/, ':date')                         # replace dates
        sql.gsub!(/'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'/, ':datetime')   # replace timestamps
        sql.gsub!(/'[^']*'/, ':string')                                   # replace strings
        sql.gsub!(/\b\d+\b/, ':int')                                      # replace integers
        sql.gsub!(/(:int,)+:int/, ':ints')                                # replace multiple ints by a list
        sql.gsub!(/(:string,)+:string/, ':strings')                       # replace multiple strings by a list

        return sql.strip
      end

      def host
        self[:host] == '' || self[:host].nil? ? self[:ip] : self[:host]
      end

      # Convert the timestamp to an integer
      def convert_timestamp(value, definition)
        _, y, m, d, h, i, s = value.split(/(\d\d)(\d\d)(\d\d)\s+(\d?\d):(\d\d):(\d\d)/)
        ('20%s%s%s%s%s%s' % [y,m,d,h.rjust(2, '0'),i,s]).to_i
      end
    end
  end
end
