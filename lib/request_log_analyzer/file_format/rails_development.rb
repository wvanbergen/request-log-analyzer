module RequestLogAnalyzer::FileFormat

  # The RailsDevelopment FileFormat is an extention to the default Rails file format. It includes
  # all lines of the normal Rails file format, but parses SQL queries and partial rendering lines
  # as well.
  class RailsDevelopment < Rails
    def self.create
      # puts 'DEPRECATED: use --rails-format development instead!'
      super('development')
    end
  end
end
