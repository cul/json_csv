require 'spec_helper'
require 'json_csv/json_to_csv'

describe JsonCsv::JsonToCsv do

  let(:dummy_class) { Class.new { include JsonCsv::JsonToCsv } }

  let(:unsorted_headers_2_records_csv_file) { fixture('round_trip/unsorted-headers-2-records.csv') }
  let(:sorted_headers_2_records_csv_file) { fixture('round_trip/sorted-headers-2-records.csv') }
  let(:example_hierarchical_json_hash_for_record_1) { JSON.parse(fixture('round_trip/example-record-1.json').read) }
  let(:example_hierarchical_json_hash_for_record_2) { JSON.parse(fixture('round_trip/example-record-2.json').read) }
  let(:example_flat_json_hash_for_record_1) { JSON.parse(fixture('round_trip/example-record-1-flat.json').read) }
  let(:example_flat_json_hash_for_record_2) { JSON.parse(fixture('round_trip/example-record-2-flat.json').read) }

  context '.create_csv_for_json_records' do
    let(:out_csv_tempfile) { Tempfile.new('out_csv') }
    let(:json_docs) {
      [example_hierarchical_json_hash_for_record_1, example_hierarchical_json_hash_for_record_2]
    }
    it "works as expected" do
      begin
        dummy_class.create_csv_for_json_records(out_csv_tempfile.path) do |csv_builder|
          json_docs.each do |json_doc|
            csv_builder.add(json_doc)
          end
        end
        expect(CSV.read(sorted_headers_2_records_csv_file.path)).to eq(CSV.read(out_csv_tempfile.path))
      ensure
        out_csv_tempfile.unlink
      end
    end
  end

  context '.json_hash_to_flat_csv_row_hash' do
    let(:example_csv_2d_array_for_2_records) { CSV.parse(unsorted_headers_2_records_csv_file.read) }
    let(:csv_header_row) { example_csv_2d_array_for_2_records[0] }
    let(:csv_data_record_1) { example_csv_2d_array_for_2_records[1] }
    let(:csv_data_record_2) { example_csv_2d_array_for_2_records[2] }

    it "returns expected values for csv row 1" do
      expect(dummy_class.json_hash_to_flat_csv_row_hash(example_hierarchical_json_hash_for_record_1)).to eq(csv_header_row.zip(csv_data_record_1).to_h.reject{|key, val| val.nil? || val == ''})
    end

    it "returns expected values for csv row 2" do
      expect(dummy_class.json_hash_to_flat_csv_row_hash(example_hierarchical_json_hash_for_record_2)).to eq(csv_header_row.zip(csv_data_record_2).to_h.reject{|key, val| val.nil? || val == ''})
    end
  end

  context '.flatten_hash' do
    it "works for row 1" do
      expect(dummy_class.flatten_hash(example_hierarchical_json_hash_for_record_1, '', {})).to eq(example_flat_json_hash_for_record_1)
    end

    it "works for row 2" do
      expect(dummy_class.flatten_hash(example_hierarchical_json_hash_for_record_2, '', {})).to eq(example_flat_json_hash_for_record_2)
    end

    context "raises an error when one of the json keys contains a bracket or period" do
      let(:hierarchical_json_hash_with_left_bracket_in_key) {
        example_hierarchical_json_hash_for_record_1['key with [ left bracket'] = 'value'
        example_hierarchical_json_hash_for_record_1
      }
      let(:hierarchical_json_hash_with_right_bracket_in_key) {
        example_hierarchical_json_hash_for_record_1['key with ] right bracket'] = 'value'
        example_hierarchical_json_hash_for_record_1
      }
      let(:hierarchical_json_hash_with_period_in_key) {
        example_hierarchical_json_hash_for_record_1['key with . period'] = 'value'
        example_hierarchical_json_hash_for_record_1
      }
      it do
        expect{ dummy_class.flatten_hash(hierarchical_json_hash_with_left_bracket_in_key, '', {}) }.to raise_error(ArgumentError)
      end
      it do
        expect{ dummy_class.flatten_hash(hierarchical_json_hash_with_right_bracket_in_key, '', {}) }.to raise_error(ArgumentError)
      end
      it do
        expect{ dummy_class.flatten_hash(hierarchical_json_hash_with_period_in_key, '', {}) }.to raise_error(ArgumentError)
      end
    end
  end

  context '.key_contains_unallowed_characters?' do
    it "returns false if key conains a left bracket, right bracket, or period" do
      ['char [ test 1', 'char ] test 2', 'char . test 3'].each do |key|
        expect(dummy_class.key_contains_unallowed_characters?(key)).to eq(true)
      end
    end

    it "returns true if key does NOT conain a left bracket, right bracket, or period" do
      expect(dummy_class.key_contains_unallowed_characters?('some regular key with random other !@#$%^&*() chars')).to eq(false)
    end
  end

end
