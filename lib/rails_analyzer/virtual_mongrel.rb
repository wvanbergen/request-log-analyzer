# Can calculate request counts, duratations, mean times etc. of all the requests given.
class VirtualMongrel
  STATUS = [:started, :completed]

  attr_reader :status
  attr_reader :start_line
  attr_reader :start_time
  attr_reader :die_line
  attr_reader :die_time
  
  attr_reader :data_hash

  def initialize(options = {})
    @status       = :started

    @start_line   = options[:start_line] || 0
    @die_line     = options[:die_line] || @start_line + 10

    @start_time   = options[:start_time] || 0
    @die_time     = options[:die_time] || @start_time + 10
    
    @data_hash    = {}
  end
  
  def group(request, &block)
    case request[:type]
      when :started 
        data_hash.store(:timestamp,   request[:timestamp])
        data_hash.store(:method,      request[:method])
        @status       = :started

      when :completed
        hash = block_given? ? yield(request) : request.hash
        data_hash.store(:request,               hash)
        data_hash.store(:total_rendering_time,  request[:rendering])
        data_hash.store(:duration,              request[:duration])
        data_hash.store(:total_db_time,         request[:db])
    
        if @calculate_database && request[:duration] && request[:rendering]
          data_hash.store(:total_db_time,  request[:duration] - request[:request])
        end
    
        @status = :completed

      when :failed
        data_hash.store(:error,               request[:error])
        data_hash.store(:exception_string,    request[:exception_string])
        @status = :completed

    end
  end
  
 
  # Store this mongrel in the database
  def save
    puts 'Saving mongrel!'
    puts data_hash.to_s
  end

end