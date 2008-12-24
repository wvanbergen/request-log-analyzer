# Can calculate request counts, duratations, mean times etc. of all the requests given.
class VirtualMongrel
  STATUS = [:started, :completed]

  attr_reader :status
  attr_reader :start_line
  attr_reader :start_time
  attr_reader :die_line
  attr_reader :die_time
  attr_reader :calculate_database
  attr_reader :running_mongrels
  
  attr_reader :data_hash

  def initialize(options = {})
    @status       = :started

    @start_line   = options[:start_line] || 0
    @die_line     = options[:die_line] || @start_line + 10

    @start_time   = options[:start_time] || 0
    @die_time     = options[:die_time] || @start_time + 10
    
    @data_hash    = {}
    @calculate_database = false
    @running_mongrels = options[:running_mongrels] || 1
  end
  
  def update_running_mongrels(number)
    @running_mongrels = number if number > @running_mongrels
  end
    
  
  def group(request, &block)
    case request[:type]
      when :started 
        data_hash.store(:timestamp,   request[:timestamp])
        data_hash.store(:method,      request[:method])
        @status       = :started

      when :completed
        data_hash.store(:url,             request[:url])
        data_hash.store(:hashed_request,  request_hasher(request))
        data_hash.store(:rendering,       request[:rendering])
        data_hash.store(:duration,        request[:duration])
        data_hash.store(:db_time,         request[:db])
    
        if @calculate_database && request[:duration] && request[:rendering]
          data_hash.store(:db_time, request[:duration] - request[:request])
        end
    
        @status = :completed

      when :failed
        data_hash.store(:error,               request[:error])
        data_hash.store(:exception_string,    request[:exception_string])
        @status = :completed

    end
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
 
  # Store this mongrel in the database
  def save
    puts 'Saving mongrel!'
    puts "Number of other running mongrels (certainty) #{running_mongrels}"
    puts data_hash.to_s
  end

end