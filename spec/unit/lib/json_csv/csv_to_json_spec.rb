require 'spec_helper'
require 'json_csv/csv_to_json'
require 'tempfile'

describe JsonCsv::CsvToJson do

  let(:dummy_class) { Class.new { include JsonCsv::CsvToJson } }

  let(:unsorted_headers_2_records_csv_file) { fixture('round_trip/unsorted-headers-2-records.csv') }
  let(:example_hierarchical_json_hash_for_record_1) { JSON.parse(fixture('round_trip/example-record-1.json').read) }
  let(:example_hierarchical_json_hash_for_record_2) { JSON.parse(fixture('round_trip/example-record-2.json').read) }

  context '.csv_file_to_hierarchical_json_hash' do
    let(:field_casting_rules) {
      {
        'number_of_pages' => 'integer',
        'is_a_great_book' => 'boolean',
        'related_books[x].number_of_pages' => 'integer',
        'related_books[x].is_a_great_book' => 'boolean'
      }
    }
    let(:expected_results) {
      [
        example_hierarchical_json_hash_for_record_1,
        example_hierarchical_json_hash_for_record_2
      ]
    }
    it "converts as expected" do
      dummy_class.csv_file_to_hierarchical_json_hash(unsorted_headers_2_records_csv_file.path, field_casting_rules) do |json_hash_for_row, i|
        expect(json_hash_for_row).to eq(expected_results[i])
      end
    end
  end

  context '.csv_row_hash_to_hierarchical_json_hash' do
    let(:csv_row_hash) do
      {
        'key[0]' => 'val0',
        'key[1]' => 'val1',
        'otherkey[2]' => 'otherval2',
        'otherkey[3]' => 'otherval3',
        'aaa[2].bbb[0].ccc' => 'true',
        'aaa[2].bbb[0].ddd' => '   eee   ',
        'empty[0].path[0].of[0].nothingness[0]' => ' '
      }
    end
    let(:field_casting_rules) do
      {
        'aaa[x].bbb[x].ccc' => 'boolean'
      }
    end
    context "works as expected, trimming string values and removing empty values by default" do
      let(:expected_cleaned) do
        {
          'key' => [
            'val0', 'val1'
          ],
          'otherkey' => [
            'otherval2', 'otherval3'
          ],
          'aaa' => [
            {
              'bbb' => [
                {
                  'ccc' => true,
                  'ddd' => 'eee'
                }
              ]
            }
          ]
        }
      end
      it do
        expect(dummy_class.csv_row_hash_to_hierarchical_json_hash(csv_row_hash, field_casting_rules)).to eq(expected_cleaned)
      end
    end

    context "does not strip string values when strip_value_whitespace arg is false" do
      let(:strip_value_whitespace) { false }
      let(:expected_without_whitespace_strip) do
        {
          'key' => [
            'val0', 'val1'
          ],
          'otherkey' => [
            'otherval2', 'otherval3'
          ],
          'aaa' => [
            {
              'bbb' => [
                {
                  'ccc' => true,
                  'ddd' => '   eee   '
                }
              ]
            }
          ]
        }
      end
      it do
        expect(dummy_class.csv_row_hash_to_hierarchical_json_hash(csv_row_hash, field_casting_rules, strip_value_whitespace)).to eq(expected_without_whitespace_strip)
      end
    end
  end

  context '.put_value_at_json_path' do
    let(:hsh) {
      {
        'top level key' => 'top level value',
        'other top level key' => [
          {
            'nested key' => 'nested value'
          }
        ]
      }
    }
    it "can place a new value at a top level path" do
      dummy_class.put_value_at_json_path(hsh, 'new top level key', 'new top level val')
      expect(hsh['new top level key']).to eq('new top level val')
    end

    it "can replace an existing value" do
      dummy_class.put_value_at_json_path(hsh, 'top level key', 'replacement value')
      expect(hsh['top level key']).to eq('replacement value')
    end

    it "creates new intermediate structures when creating a new nested value, and can handle spaces and other non-alpha chars in the nested hash keys" do
      dummy_class.put_value_at_json_path(hsh, 'new top level key[1].deeper_value[3].low-level cool value!', 'deeply nested value')
      expect(hsh['new top level key'][1]['deeper_value'][3]['low-level cool value!']).to eq('deeply nested value')
    end

    it "can handle json paths that have consecuritve numeric array indexes" do
      dummy_class.put_value_at_json_path(hsh, 'new top level key[0][1][2][3]', 'deeply nested value')
      expect(hsh['new top level key'][0][1][2][3]).to eq('deeply nested value')
    end

    it "can handle json paths that have consecutive string hash indexes" do
      dummy_class.put_value_at_json_path(hsh, 'new top level key.deeper_value.low-level cool value!', 'deeply nested value')
      expect(hsh['new top level key']['deeper_value']['low-level cool value!']).to eq('deeply nested value')
    end
  end

  context 'json_path conversion' do
    let(:path) { "related_books[1].notes_from_reviewers[0]" }
    let(:pieces) { ["related_books", 1, "notes_from_reviewers", 0] }

    context '.pieces_to_json_path' do
      it "generates the expected pieces" do
        expect(dummy_class.pieces_to_json_path(pieces)).to eq(path)
      end

      it "works for a single piece" do
        expect(dummy_class.pieces_to_json_path(['something'])).to eq('something')
      end
    end

    context '.json_path_to_pieces' do
      it "generates the expected pieces" do
        expect(dummy_class.json_path_to_pieces(path)).to eq(pieces)
      end

      it "works for a simple path that only contains a top level key" do
        expect(dummy_class.json_path_to_pieces('something')).to eq(['something'])
      end

      it "works properly for a json_path that only contains one numeric index (e.g. '[0]')" do
        expect(dummy_class.json_path_to_pieces('[0]')).to eq([0])
      end
    end
  end

  context '.apply_field_casting_type' do

    it "casts to integer" do
      expect(dummy_class.apply_field_casting_type('1', 'integer')).to eq(1)
      expect{dummy_class.apply_field_casting_type('1.0', 'integer')}.to raise_error(ArgumentError)
      expect{dummy_class.apply_field_casting_type('not a number', 'integer')}.to raise_error(ArgumentError)
    end

    it "casts to float" do
      expect(dummy_class.apply_field_casting_type('1.2345', 'float')).to eq(1.2345)
      expect(dummy_class.apply_field_casting_type('.2345', 'float')).to eq(0.2345)
      expect(dummy_class.apply_field_casting_type('1', 'float')).to eq(1.0)
      expect{dummy_class.apply_field_casting_type('not a number', 'float')}.to raise_error(ArgumentError)
      expect{dummy_class.apply_field_casting_type('1.', 'float')}.to raise_error(ArgumentError)
    end

    it "casts to boolean" do
      expect(dummy_class.apply_field_casting_type('true', 'boolean')).to eq(true)
      expect(dummy_class.apply_field_casting_type('TRUE', 'boolean')).to eq(true)
      expect(dummy_class.apply_field_casting_type('TrUe', 'boolean')).to eq(true)
      expect(dummy_class.apply_field_casting_type('false', 'boolean')).to eq(false)
      expect(dummy_class.apply_field_casting_type('FALSE', 'boolean')).to eq(false)
      expect(dummy_class.apply_field_casting_type('FaLsE', 'boolean')).to eq(false)
      expect{dummy_class.apply_field_casting_type('any other value', 'boolean')}.to raise_error(ArgumentError)
    end

    it "casts to string" do
      expect(dummy_class.apply_field_casting_type('a string', 'string')).to eq('a string')
    end

    it 'rejects invalid casting type' do
      expect{dummy_class.apply_field_casting_type('value to cast', 'unicorn')}.to raise_error(ArgumentError)
    end
  end

  context '.real_json_path_to_field_casting_rule_pattern' do
    it "converts as expected" do
      expect(dummy_class.real_json_path_to_field_casting_rule_pattern("related_books[1].notes_from_reviewers[0]")).to eq("related_books[x].notes_from_reviewers[x]")
    end
  end

end
