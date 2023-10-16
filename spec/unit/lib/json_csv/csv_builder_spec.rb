# frozen_string_literal: true

require 'spec_helper'
require 'json_csv/csv_builder'

describe JsonCsv::CsvBuilder do
  let(:out_csv_tempfile) { Tempfile.new('out_csv') }
  let(:json_doc) do
    {
      'top_level_key1' => [
        {
          'mid_level_key' => {
            'low_level_key1' => 'value1',
            'low_level_key2' => 'value2'
          }
        }
      ],
      'top_level_key2' => 'zzz'
    }
  end
  let(:expected_csv_headers_to_indexes) do
    {
      'top_level_key1[0].mid_level_key.low_level_key1' => 0,
      'top_level_key1[0].mid_level_key.low_level_key2' => 1,
      'top_level_key2' => 2
    }
  end
  let(:expected_csv_content) do
    [['value1', 'value2', 'zzz']]
  end

  it 'has a private constructor' do
    expect { described_class.new }.to raise_error(NoMethodError)
  end

  describe '.original_header_indexes_to_sorted_indexes' do
    let(:column_header_comparator) do
      JsonCsv::JsonToCsv::ClassMethods::DEFAULT_HEADER_SORT_COMPARATOR
    end
    let(:original_headers) do
      ['zzz', 'bbb[1].ccc[2]', 'bbb[1].ccc[1]', 'aaa', 'bbb[1].ccc[10]']
    end
    let(:expected_sorted_headers) do
      ['aaa', 'bbb[1].ccc[1]', 'bbb[1].ccc[2]', 'bbb[1].ccc[10]', 'zzz']
    end

    it 'sorts properly' do
      original_to_sorted_index_map = described_class.original_header_indexes_to_sorted_indexes(original_headers,
                                                                                               column_header_comparator)
      original_to_sorted_index_map.each do |original_index, sorted_index|
        expect(original_headers[original_index]).to eq(expected_sorted_headers[sorted_index])
      end
    end
  end

  describe '.create_csv_without_headers' do
    it 'works as expected' do
      headers = described_class.create_csv_without_headers(out_csv_tempfile.path, 'wb') do |csv_builder|
        csv_builder.add(json_doc)
      end

      expect(CSV.read(out_csv_tempfile.path)).to eq(expected_csv_content)
      expect(headers).to eq(expected_csv_headers_to_indexes.keys)
    end
  end

  describe '#add' do
    it 'works as expected' do
      csv_builder = nil
      CSV.open(out_csv_tempfile.path, 'wb') do |csv|
        csv_builder = described_class.send(:new, csv)
        csv_builder.add(json_doc)
      end
      expect(CSV.read(out_csv_tempfile.path)).to eq(expected_csv_content)
      expect(csv_builder.known_headers_to_indexes).to eq(expected_csv_headers_to_indexes)
    end
  end
end
