module RequestLogAnalyzer::FileFormat

  class Mysql < Base
    line_definition :time do |line|
      line.regexp = /\# Time: (\d\d\d\d\d\d \d{1,2}:\d\d:\d\d)/
      line.captures << { :name => :timestamp, :type => :timestamp }
      line.header = true
    end

    line_definition :meta_info do |line|
      line.regexp = /\# User\@Host\: (\w+)\[(.*?)\].*/
      line.captures << { :name => :user, :type => :string } << 
                       { :name => :host, :type => :string }
    end

    line_definition :query_info do |line|
      line.regexp = /\# Query_time: (\d+)  Lock_time: (\d+)  Rows_sent: (\d+)  Rows_examined: (\d+)/
      line.captures << { :name => :query_time, :type => :duration, :unit => :sec } <<
                       { :name => :lock_time, :type => :duration, :unit => :sec } <<
                       { :name => :rows_sent, :type => :integer } <<
                       { :name => :rows_examined, :type => :integer }
    end

    line_definition :query do |line|
      line.regexp = /(.*;)/
      line.captures << { :name => :query, :type => :sql }
      line.footer = true
    end

    RQ = Proc.new { |request| "#{request[:user]}@#{request[:host]}: #{request[:query]}" }
    RU = Proc.new { |request| "#{request[:user]}" }

    report do |analyze|
      analyze.frequency :user, :title => "Top 20 of users with most queries", :amount => 20
      analyze.duration :query_time, :category => RU, :title => 'Total query duration per user'
      analyze.duration :query_time, :category => RQ, :title => 'Top 50 queries by duration', :amount => 50
      analyze.count :query, :category => RQ, :title => "Top queries by total rows examined", :amount => 20
      analyze.count :rows_sent, :category => RQ, :title => "Top queries by rows sent", :amount => 20
    end
  
    class Request < RequestLogAnalyzer::Request
      def convert_sql(sql, definition)
        converted = sql.gsub(/\b\d+\b/, ':int').gsub(/`([^`]+)`/, '\1').gsub(/'[^']*'/, ':string').rstrip
        converted.gsub!(/(:int,)+:int/, ':ints')
        converted.gsub!(/(:string,)+:string/, ':strings')
        converted
      end
    
      def convert_timestamp(stamp, definition)
        all,y,m,d,h,i,s = stamp.split(/(\d\d)(\d\d)(\d\d) (\d?\d):(\d\d):(\d\d)/)
        "20#{y}#{m}#{d}#{h}#{i}#{s}".to_i
      end
    end
  end

end