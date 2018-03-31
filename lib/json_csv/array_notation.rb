module JsonCsv
  module ArrayNotation
    BRACKETS = 'brackets'.freeze
    DASH = 'dash'.freeze

    VALID_ARRAY_NOTATIONS = [BRACKETS, DASH].freeze

    def self.bracket_header_to_dash_header(bracket_header)
      bracket_header
    end

    def self.dash_header_to_bracket_header(dash_header)
      dash_header
    end

  end
end
