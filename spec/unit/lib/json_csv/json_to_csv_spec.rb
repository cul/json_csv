require 'spec_helper'
require 'json_csv/json_to_csv'

describe JsonCsv::JsonToCsv do

  let(:dummy_class) { Class.new { extend JsonCsv::JsonToCsv } }

  let(:example_hierarchical_json_hash_for_record_1) { JSON.parse(fixture('round_trip/example-record-1.json').read) }
  let(:example_hierarchical_json_hash_for_record_2) { JSON.parse(fixture('round_trip/example-record-2.json').read) }
  let(:example_flat_json_hash_for_record_1) { JSON.parse(fixture('round_trip/example-record-1-flat.json').read) }
  let(:example_flat_json_hash_for_record_2) { JSON.parse(fixture('round_trip/example-record-2-flat.json').read) }

  context '.json_hash_to_flat_csv_row_hash' do
    let(:example_csv_2d_array_for_2_records) { CSV.parse(fixture('round_trip/example-2-records.csv').read) }
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
    it "returns false if key conains a left bracket, right bracker, or period" do
      ['char [ test 1', 'char ] test 2', 'char . test 3'].each do |key|
        expect(dummy_class.key_contains_unallowed_characters?(key)).to eq(true)
      end
    end

    it "returns true if key does NOT conain a left bracket, right bracker, or period" do
      expect(dummy_class.key_contains_unallowed_characters?('some regular key with random other !@#$%^&*() chars')).to eq(false)
    end
  end

end
