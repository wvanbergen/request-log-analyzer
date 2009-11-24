module RequestLogAnalyzer::FileFormat
  
  class Sinatra < Apache

    def self.create(*args)
      super(:sinatra, *args)
    end

  end

end
