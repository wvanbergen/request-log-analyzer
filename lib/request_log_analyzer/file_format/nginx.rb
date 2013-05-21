module RequestLogAnalyzer::FileFormat

  class Nginx < Apache

    def self.create(*args)
      super(:combined, *args)
    end
  end
end
