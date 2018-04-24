require 'json'
require 'json_csv/csv_builder'

module JsonCsv
  module JsonToCsv

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      BRACKET_HEADER_SORT_COMPARATOR = lambda do |header1, header2|
        # Ensure correct alphabetical sorting AND numeric sorting via zero-padding of numbers
        header1_with_zero_padding = header1.gsub(/(?<=\[)\d+(?=\])/) { |capture| capture.to_i.to_s.rjust(5, '0') }
        header2_with_zero_padding = header2.gsub(/(?<=\[)\d+(?=\])/) { |capture| capture.to_i.to_s.rjust(5, '0') }
        header1_with_zero_padding <=> header2_with_zero_padding
      end

      DASH_HEADER_SORT_COMPARATOR = lambda do |header1, header2|
        # Ensure correct alphabetical sorting AND numeric sorting via zero-padding of numbers
        header1_with_zero_padding = (header1 + '.').gsub(/(?<=-)\d+(?=\.)/) { |capture| capture.to_i.to_s.rjust(5, '0') }[0...-1]
        header2_with_zero_padding = (header2 + '.').gsub(/(?<=-)\d+(?=\.)/) { |capture| capture.to_i.to_s.rjust(5, '0') }[0...-1]
        header1_with_zero_padding <=> header2_with_zero_padding
      end

      # Example usage:
      # create_csv_for_json_records('/path/to/file.csv', JsonCsv::ArrayNotation::BRACKETS) do |csv_builder|
      #   json_docs.each do |json_doc|
      #     csv_builder.add(json_hash)
      #   end
      # end
      def create_csv_for_json_records(csv_outfile_path, array_notation)
        csv_temp_outfile_path = csv_outfile_path + '.temp'

        # Step 1: Build CSV with unsorted headers in temp file
        csv_headers = JsonCsv::CsvBuilder.create_csv_without_headers(csv_temp_outfile_path, array_notation, 'wb') do |csv_builder|
          yield csv_builder
        end

        header_sort_comparator = array_notation == JsonCsv::ArrayNotation::DASH ? DASH_HEADER_SORT_COMPARATOR : BRACKET_HEADER_SORT_COMPARATOR

        # Step 2: Sort CSV columns by header, based on column_header_comparator
        original_to_sorted_index_map = JsonCsv::CsvBuilder.original_header_indexes_to_sorted_indexes(csv_headers, header_sort_comparator)
        CSV.open(csv_outfile_path, 'wb') do |final_csv|
          # Open temporary CSV for reading
          CSV.open(csv_temp_outfile_path, 'rb') do |temp_csv|

            # write out ordered header row
            reordered_header_row = []
            csv_headers.each_with_index do |header, index|
              reordered_header_row[original_to_sorted_index_map[index]] = header
            end

            final_csv << reordered_header_row

            temp_csv.each do |temp_csv_row|
              reordered_temp_csv_row = []
              # write out ordered data row
              temp_csv_row.each_with_index do |cell_value, index|
                reordered_temp_csv_row[original_to_sorted_index_map[index]] = cell_value
              end
              final_csv << reordered_temp_csv_row
            end
          end
        end
      end

      # Converts the given json_hash into a flat csv hash, converting all values to
      # strings (because CSVs are dumb and don't store info about data types)
      # Set first_index to 1 if you want the first element in an array to
      #
      def json_hash_to_flat_csv_row_hash(json_hash, array_notation)
        flat = flatten_hash(json_hash)
        # Convert values to strings because in the CSV file, all values are strings
        flat.each { |key, val| flat[key] = val.nil? ? '' : val.to_s }
        # If we're using dash array notation, convert the headers
        if array_notation == JsonCsv::ArrayNotation::DASH
          Hash[flat.map { |key, val| [JsonCsv::ArrayNotation.bracket_header_to_dash_header(key), val] }]
        else
          flat
        end
      end

      # This method calls itself recursively while flattening a hash, and during
      # this sequence of calls the obj param may either be a hash or an array.
      def flatten_hash(obj, parent_path = '', flat_hash_to_build = {})
        if obj.is_a?(Hash)
          obj.each do |key, val|
            if key_contains_unallowed_characters?(key)
              raise ArgumentError, 'Cannot deal with hash keys that contain "[" or "]" or "." because these characters have special meanings in CSV headers.'
            end
            path = parent_path + (parent_path.empty? ? '' : '.') + key
            flatten_hash(val, path, flat_hash_to_build)
          end
        elsif obj.is_a?(Array)
          obj.each_with_index do |el, index|
            path = parent_path + "[#{index}]"
            flatten_hash(el, path, flat_hash_to_build)
          end
        else
          flat_hash_to_build[parent_path] = obj unless obj.nil? || obj == '' # ignore nil or empty string values
        end

        flat_hash_to_build
      end

      def key_contains_unallowed_characters?(key)
        return true if key.index('[') || key.index(']') || key.index('.')
        false
      end
    end

  end
end
