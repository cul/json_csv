require 'csv'
require 'json_csv/json_to_csv'

module JsonCsv
  class CsvBuilder
    private_class_method :new # private constructor. we don't want users to initialize this class.
    attr_reader :known_headers_to_indexes # map of all headers seen by this CsvBuilder, mapped to their column order indexes

    def initialize(open_csv_handle, array_notation)
      @array_notation = array_notation
      @known_headers_to_indexes = {}
      @open_csv_handle = open_csv_handle
    end

    # Adds data from the given json hash to the CSV we're building.
    def add(json_hash)
      row_to_write = []
      JsonCsv.json_hash_to_flat_csv_row_hash(json_hash, @array_notation).each do |column_header, cell_value|
        known_headers_to_indexes[column_header] = known_headers_to_indexes.length unless known_headers_to_indexes.key?(column_header)
        row_to_write[known_headers_to_indexes[column_header]] = cell_value
      end
      @open_csv_handle << row_to_write
    end

    # Writes out a CSV file that does NOT contain a header row. Only data values.
    # Returns an array of headers that correspond to the written-out CSV file's columns.
    #
    # Why don't we include CSV headers in the CSV?  Because don't know what set of headers
    # we're working with while we dynamically create this CSV.  Different JSON documents may
    # or may not all contain the same headers. For this reason, this is more of an internal
    # method that isn't called directly by users of this gem.
    def self.create_csv_without_headers(csv_outfile_path, array_notation, csv_write_mode = 'wb')
      csv_builder = nil

      CSV.open(csv_outfile_path, csv_write_mode) do |csv|
        csv_builder = new(csv, array_notation)
        yield csv_builder
      end

      csv_builder.known_headers_to_indexes.keys
    end

    def self.original_header_indexes_to_sorted_indexes(csv_headers, column_header_comparator)
      original_headers_to_indexes = Hash[csv_headers.map.with_index { |header, index| [header, index] }]
      headers_to_sorted_indexes = Hash[csv_headers.sort(&column_header_comparator).map.with_index { |header, index| [header, index] }]
      original_to_sorted_index_map = {}
      original_headers_to_indexes.each do |header, original_index|
        original_to_sorted_index_map[original_index] = headers_to_sorted_indexes[header]
      end
      original_to_sorted_index_map
    end

  end
end
