module JsonCsv
  module ArrayNotation
    BRACKETS = 'BRACKETS'.freeze
    DASH = 'DASH'.freeze

    VALID_ARRAY_NOTATIONS = [BRACKETS, DASH].freeze

    def self.bracket_header_to_dash_header(bracket_header)
      # e.g. replace occurrences of '[1]' with '-1'
      bracket_header.gsub(/(\[(\d+)\])/, '-\2')
    end

    def self.dash_header_to_bracket_header(dash_header)
      # e.g. replace occurrences of '-1' with '[1]'
      dash_header.gsub(/(-(\d+))/, '[\2]')
    end

    def self.raise_error_if_invalid_array_notation_value!(error_class, array_notation)
      raise error_class, "Invalid array notation. Must be one of #{VALID_ARRAY_NOTATIONS.join(' or ')}." unless VALID_ARRAY_NOTATIONS.include?(array_notation)
    end

  end
end
