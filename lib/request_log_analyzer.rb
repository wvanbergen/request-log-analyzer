require File.dirname(__FILE__) + '/../lib/base/log_parser'
require File.dirname(__FILE__) + '/../lib/base/summarizer'
require File.dirname(__FILE__) + '/../lib/rails_analyzer/log_parser'
require File.dirname(__FILE__) + '/../lib/rails_analyzer/summarizer'
require File.dirname(__FILE__) + '/../lib/rails_analyzer/virtual_mongrel.rb'
require File.dirname(__FILE__) + '/../lib/merb_analyzer/log_parser'
require File.dirname(__FILE__) + '/../lib/merb_analyzer/summarizer'
require File.dirname(__FILE__) + '/../lib/bashcolorizer'
require File.dirname(__FILE__) + '/../lib/ruby-progressbar/progressbar.rb'

# Can calculate request counts, duratations, mean times etc. of all the requests given.
class RequestLogAnalyzer
  attr_reader :log_parser_class
  attr_reader :summerizer
  attr_reader :arguments
  attr_reader :line_types
  attr_reader :amount
  attr_reader :fast

  # Initializer. Sets global variables
  # Options
  # *<tt>:fast</tt> Only look at request initializers. Faster, but not not all outputs are shown.
  # *<tt>:guess_database_time</tt> Guess database time if it it not in the log (default for Rails produciton).
  # *<tt>:merb</tt> Use merb summarizer and parser classes instead of rails.
  # *<tt>:output_reports</tt> Comma separated string of requested output reports
  # *<tt>:amount</tt> Amount of lines shown for each result table. Defaults to 10.
  def initialize(options = {})
    @fast                 = options[:fast] || false
    @guess_database_time  = options[:guess_database_time] || false

    if options[:merb]
      @summarizer       = MerbAnalyzer::Summarizer.new(:calculate_database => @guess_database_time)
      @log_parser_class = MerbAnalyzer::LogParser
    else
      @summarizer       = RailsAnalyzer::Summarizer.new(:calculate_database => @guess_database_time)
      @log_parser_class = RailsAnalyzer::LogParser
    end

    @output_reports = options[:output].split(', ') rescue [:timespan, :most_requested, :total_time, :mean_time, :total_db_time, :mean_db_time, :mean_rendering_time, :blockers, :hourly_spread, :errors] 
    @amount       = options[:amount] || 10

    @line_types = @log_parser_class::LOG_LINES.keys
    @line_types = [:completed] if @fast
  end
 

  # Substitutes variable elements in a url (like the id field) with a fixed string (like ":id")
  # This is used to aggregate simular requests. 
  # <tt>request</tt> The request to evaluate.
  # Returns uniformed url string.
  # Raises on mailformed request.
  def request_hasher(request)
    if request[:url]
      url = request[:url].downcase.split(/^http[s]?:\/\/[A-z0-9\.-]+/).last.split('?').first # only the relevant URL part
      url << '/' if url[-1] != '/'[0] && url.length > 1 # pad a trailing slash for consistency

      url.gsub!(/\/\d+-\d+-\d+(\/|$)/, '/:date') # Combine all (year-month-day) queries
      url.gsub!(/\/\d+-\d+(\/|$)/, '/:month') # Combine all date (year-month) queries
      url.gsub!(/\/\d+[\w-]*/, '/:id') # replace identifiers in URLs

      return url
    elsif request[:controller] && request[:action]
      return "#{request[:controller]}##{request[:action]}"
    else
      raise 'Cannot hash this request! ' + request.inspect
    end
  end

  # Print results using a ASCII table.
  # <tt>summarizer</tt> The summarizer containg information to draw the table.
  # <tt>field</tt> The field containing the data to be printed
  # <tt>amount</tt> The length of the table (defaults to 20)
  def print_table(summarizer, field, amount = @amount)
    summarizer.sort_actions_by(field).reverse[0, amount.to_i].each do |a|
      # As we show count by default, show totaltime if we sort by count
      field = :total_time if field == :count

      puts "%-50s: %10.03fs [#{green("%d requests")}]" % [a[0], a[1][field], a[1][:count]]
    end
  end

  # Execute the analyze
  def analyze_this(files = [])
    # Walk through al the files given via the arguments.
    files.each do |log_file|
      puts "Processing #{@line_types.join(', ')} log lines from #{log_file}..."

      parser = @log_parser_class.new(log_file)

      # add progress bar 
      unless @fast
        pbar = ProgressBar.new(green(log_file), File.size(log_file))
        parser.progress { |pos, total| (pos == :finished) ? pbar.finish : pbar.set(pos) }
      end

      parser.each(*line_types) do |request|
        @summarizer.group(request)  { |r| request_hasher(r) }
      end
    end

    # Select the reports to output and generate them.
    @output_reports.each do |report|
      report_location = "#{File.dirname(__FILE__)}/../output/#{report}.rb"

      if File.exist?(report_location)
        eval File.read(report_location)
      else
        puts "\nERROR: Output report #{report} not found!"
      end
    end
  end
  
  def analyze_with_virtual_mongrels(files = [])
    # Walk through al the files given via the arguments.
    files.each do |log_file|
      puts "Processing #{@line_types.join(', ')} log lines from #{log_file}..."

      parser = @log_parser_class.new(log_file)

      virtual_mongrels = []
      
      line = 0

      parser.each(*line_types) do |request|
        line += 1

        puts "Number of mongrels: #{virtual_mongrels.length}"
        puts "Line number: #{line}"

        case request[:type]   
          when :started
            puts 'Spawned new virtual mongrel'
            new_mongrel = VirtualMongrel.new(:start_line => line, :calculate_database => @guess_database_time, :running_mongrels => virtual_mongrels.length + 1)
            new_mongrel.group(request)
            virtual_mongrels << new_mongrel
          else
            completed_mongrel = virtual_mongrels.first
            completed_mongrel.group(request)
            completed_mongrel.update_running_mongrels(virtual_mongrels.length)
            completed_mongrel.save
        end
        
        keep_virtual_mongrels = []
        
        virtual_mongrels.each do |mongrel|
          if mongrel.die_line >= line && mongrel.status == :started
            keep_virtual_mongrels << mongrel 
          else
            puts 'Destroyed virtual mongrel!'
            puts ""

          end
        end
        
        virtual_mongrels = keep_virtual_mongrels
            
      end
    end

  end
end