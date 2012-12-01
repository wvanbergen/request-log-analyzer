module RequestLogAnalyzer::FileFormat

  class Nginx < Apache

    def self.create(*args)
      super(:nginx, *args)
    end
  end
end
