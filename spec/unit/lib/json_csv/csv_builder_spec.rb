require 'spec_helper'
require 'json_csv/csv_builder'

describe JsonCsv::CsvBuilder do
  it "has a private constructor" do
    expect{ JsonCsv::CsvBuilder.new }.to raise_error(NoMethodError)
  end

  context '.original_header_indexes_to_sorted_indexes' do
    let(:column_header_comparator) {
      JsonCsv::JsonToCsv::ClassMethods::DEFAULT_HEADER_SORT_COMPARATOR
    }
    let(:original_headers) {
      ['zzz', 'bbb[1].ccc[2]', 'bbb[1].ccc[1]', 'aaa', 'bbb[1].ccc[10]']
    }
    let(:expected_sorted_headers) {
      ['aaa', 'bbb[1].ccc[1]', 'bbb[1].ccc[2]', 'bbb[1].ccc[10]', 'zzz']
    }
    it 'sorts properly' do
      original_to_sorted_index_map = described_class.original_header_indexes_to_sorted_indexes(original_headers, column_header_comparator)
      original_to_sorted_index_map.each do |original_index, sorted_index|
        expect(original_headers[original_index]).to eq(expected_sorted_headers[sorted_index])
      end
    end
  end

  context do
    let(:out_csv_tempfile) { Tempfile.new('out_csv') }
    let(:json_doc) {
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
    }
    let(:expected_csv_headers_to_indexes) {
      {
        'top_level_key1[0].mid_level_key.low_level_key1' => 0,
        'top_level_key1[0].mid_level_key.low_level_key2' => 1,
        'top_level_key2' => 2
      }
    }
    let(:expected_csv_content) {
      [['value1', 'value2', 'zzz']]
    }

    context '.create_csv_without_headers' do
      it "works as expected" do
        headers = JsonCsv::CsvBuilder.create_csv_without_headers(out_csv_tempfile.path, 'wb') do |csv_builder|
          csv_builder.add(json_doc)
        end

        expect(CSV.read(out_csv_tempfile.path)).to eq(expected_csv_content)
        expect(headers).to eq(expected_csv_headers_to_indexes.keys)
      end
    end

    context '#add' do
      it "works as expected" do
        csv_builder = nil
        CSV.open(out_csv_tempfile.path, 'wb') do |csv|
          csv_builder = JsonCsv::CsvBuilder.send(:new, csv)
          csv_builder.add(json_doc)
        end
        expect(CSV.read(out_csv_tempfile.path)).to eq(expected_csv_content)
        expect(csv_builder.known_headers_to_indexes).to eq(expected_csv_headers_to_indexes)
      end
    end
  end

end
