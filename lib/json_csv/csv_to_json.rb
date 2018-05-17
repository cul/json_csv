require 'json_csv/utils'
require 'csv'

module JsonCsv
  module CsvToJson

    TYPE_STRING = 'string'.freeze
    TYPE_INTEGER = 'integer'.freeze
    TYPE_FLOAT = 'float'.freeze
    TYPE_BOOLEAN = 'boolean'.freeze
    FIELD_CASTING_TYPES = [TYPE_STRING, TYPE_INTEGER, TYPE_FLOAT, TYPE_BOOLEAN].freeze

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # Takes flat csv data and yields to a block for each row,
      # presenting that row as un-flattened json.
      # This method works for large CSVs and uses very little memory
      # because it only keeps one row in memory at a time.
      # Sample usage: csv_file_to_hierarchical_json_hash(path_to_csv, field_casting_rules = {}, strip_value_whitespace = true) do |row_json_hash, row_number|
      def csv_file_to_hierarchical_json_hash(path_to_csv, field_casting_rules = {}, strip_value_whitespace = true)
        i = 1 # start with row 1 because this corresponds to the first row of 0-indexed CSV data
        CSV.foreach(path_to_csv, headers: true, header_converters: lambda { |header|
          header.strip # remove leading and trailing header whitespace
        }) do |row_data_hash|
          yield csv_row_hash_to_hierarchical_json_hash(row_data_hash, field_casting_rules, strip_value_whitespace), i
          i += 1
        end
      end

      def csv_row_hash_to_hierarchical_json_hash(row_data_hash, field_casting_rules, strip_value_whitespace = true)
        hierarchical_hash = {}
        row_data_hash.each do |key, value|
          next if value.nil? || value == '' # ignore nil or empty string values
          put_value_at_json_path(hierarchical_hash, key, value, field_casting_rules)
        end
        # Clean up empty array elements, which may have come about from CSV data
        # that was 1-indexed instead of 0-indexed.
        JsonCsv::Utils.recursively_remove_blank_fields!(hierarchical_hash)
        JsonCsv::Utils.recursively_strip_value_whitespace!(hierarchical_hash) if strip_value_whitespace
        hierarchical_hash
      end

      # For the given obj, puts the given value at the given json_path,
      # creating nested elements as needed. This method calls itself
      # recursively when placing a value at a nested path, and during
      # this sequence of calls the obj param may either be a hash or an array.
      def put_value_at_json_path(obj, json_path, value, field_casting_rules = {}, full_json_path_from_top = json_path)
        json_path_pieces = json_path_to_pieces(json_path)

        if json_path_pieces.length == 1
          # If the full_json_path_from_top matches one of the field_casting_rules,
          # then case this field to the specified cast type
          full_json_path_from_top_as_field_casting_rule_pattern = real_json_path_to_field_casting_rule_pattern(full_json_path_from_top)
          obj[json_path_pieces[0]] = field_casting_rules.key?(full_json_path_from_top_as_field_casting_rule_pattern) ? apply_field_casting_type(value, field_casting_rules[full_json_path_from_top_as_field_casting_rule_pattern]) : value
        else
          obj[json_path_pieces[0]] ||= (json_path_pieces[1].is_a?(Integer) ? [] : {})
          put_value_at_json_path(obj[json_path_pieces[0]], pieces_to_json_path(json_path_pieces[1..-1]), value, field_casting_rules, full_json_path_from_top)
        end
      end

      # Takes a real json_path like "related_books[1].notes_from_reviewers[0]" and
      # converts it to a field_casting_rule_pattern like: "related_books[x].notes_from_reviewers[x]"
      def real_json_path_to_field_casting_rule_pattern(full_json_path_from_top)
        full_json_path_from_top.gsub(/\d+/, 'x')
      end

      def apply_field_casting_type(value, field_casting_type)
        raise ArgumentError, "Invalid cast type #{field_casting_type}" unless FIELD_CASTING_TYPES.include?(field_casting_type)

        case field_casting_type
        when TYPE_INTEGER
          raise ArgumentError, "\"#{value}\" is not an integer" unless value =~ /^[0-9]+$/
          value.to_i
        when TYPE_FLOAT
          raise ArgumentError, "\"#{value}\" is not a float" unless value =~ /^[0-9]+(\.[0-9]+)*$/ || value =~ /^\.[0-9]+$/
          value.to_f
        when TYPE_BOOLEAN
          if value.downcase == 'true'
            true
          elsif value.downcase == 'false'
            false
          else
            raise ArgumentError, "\"#{value}\" is not a boolean"
          end
        else
          value # fall back to string, which is the original form
        end
      end

      # Takes the given json_path and splits it into individual json path pieces.
      # e.g. Takes "related_books[1].notes_from_reviewers[0]" and converts it to:
      # ["related_books", 1, "notes_from_reviewers", 0]
      def json_path_to_pieces(json_path)
        # split on...
        # '].' (when preceded by a number)
        # OR
        # '[' (when followed by a number)
        # OR
        # ']' (when preceded by a number)
        # OR
        # '.' (always)
        # ...and remove empty elements (which only come up when you're working with
        # a json_path like '[0]', which splits between the first bracket and the number)
        pieces = json_path.split(/(?<=\d)\]\.|\[(?=\d)|(?<=\d)\]|\./).reject { |piece| piece == '' }
        pieces.map { |piece| piece.to_i.to_s == piece ? piece.to_i : piece } # numeric pieces should be actual numbers
      end

      # Generates a string json path from the given pieces
      # e.g. Takes ["related_books", 1, "notes_from_reviewers", 0] and converts it to:
      # "related_books[1].notes_from_reviewers[0]"
      def pieces_to_json_path(pieces)
        json_path = ''
        pieces.each do |piece|
          if piece.is_a?(Integer)
            json_path += "[#{piece}]"
          else
            json_path += '.' unless json_path.empty?
            json_path += piece
          end
        end
        json_path
      end

    end
  end
end
