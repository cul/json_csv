# frozen_string_literal: false

require 'spec_helper'
require 'json_csv/utils'

describe JsonCsv::Utils do
  describe '.removable_value?' do
    let(:removable_examples) do
      [
        '',
        '           ',
        "\n",
        {},
        [],
        nil
      ]
    end
    let(:non_removable_examples) do
      [
        'something',
        true,
        false,
        0,
        1,
        { 'key' => 'val' },
        { 'key' => nil },
        ['val'],
        [nil]
      ]
    end

    it 'works as expected' do
      removable_examples.each do |removable_value|
        expect(described_class.removable_value?(removable_value)).to eq(true)
      end

      non_removable_examples.each do |non_removable_value|
        expect(described_class.removable_value?(non_removable_value)).to eq(false)
      end
    end
  end

  describe '.recursively_remove_blank_fields!' do
    context 'works for a hash with nested values' do
      let(:input) do
        {
          'key1' => 'value',
          'key2' => '',
          'key3' => ['a'],
          'key4' => [],
          'key5' => {
            '2nd-level-key1' => [
              nil
            ],
            '2nd-level-key2' => {
              'third-level-key1' => ''
            }
          },
          'key6' => {
            '2nd-level-key1' => [],
            '2nd-level-key2' => {
              '3rd-level-key1' => {
                '4th-level-key1' => 'value'
              }
            }
          },
          'key7' => [
            [
              [
                [
                  nil
                ]
              ]
            ],
            [
              [
                [
                  0
                ]
              ]
            ],
            [
              [
                [
                  false
                ]
              ]
            ]
          ]
        }
      end
      let(:expected_output) do
        {
          'key1' => 'value',
          'key3' => ['a'],
          'key6' => {
            '2nd-level-key2' => {
              '3rd-level-key1' => {
                '4th-level-key1' => 'value'
              }
            }
          },
          'key7' => [
            [
              [
                [
                  0
                ]
              ]
            ],
            [
              [
                [
                  false
                ]
              ]
            ]
          ]
        }
      end

      it do
        expect(described_class.recursively_remove_blank_fields!(input)).to eq(expected_output)
        expect(input).to eq(expected_output)
      end
    end

    context 'works when outermost element is an array' do
      let(:input) do
        [
          [nil],
          'value'
        ]
      end
      let(:expected_output) do
        [
          'value'
        ]
      end

      it do
        expect(described_class.recursively_remove_blank_fields!(input)).to eq(expected_output)
        expect(input).to eq(expected_output)
      end
    end
  end

  describe '.recursively_strip_value_whitespace!' do
    context 'works for a hash with nested values' do
      let(:input) do
        {
          'key1' => 'value',
          'key2' => '   value   ',
          'key3' => {
            '2nd-level-key1' => {
              '3rd-level-key1' => {
                '4th-level-key1' => '   value   '
              }
            }
          },
          'key4' => [
            [
              [
                'value', '      value 2', 'value 3      ', '   value 4   '
              ]
            ]
          ]
        }
      end
      let(:expected_output) do
        {
          'key1' => 'value',
          'key2' => 'value',
          'key3' => {
            '2nd-level-key1' => {
              '3rd-level-key1' => {
                '4th-level-key1' => 'value'
              }
            }
          },
          'key4' => [
            [
              [
                'value', 'value 2', 'value 3', 'value 4'
              ]
            ]
          ]
        }
      end

      it 'transforms as expected' do
        expect(described_class.recursively_strip_value_whitespace!(input)).to eq(expected_output)
        expect(input).to eq(expected_output)
      end
    end

    context 'works when outermost element is an array' do
      let(:input) do
        [
          ['   a   '],
          '   value   '
        ]
      end
      let(:expected_output) do
        [
          ['a'],
          'value'
        ]
      end

      it do
        expect(described_class.recursively_strip_value_whitespace!(input)).to eq(expected_output)
        expect(input).to eq(expected_output)
      end
    end

    context 'works for a plain string' do
      let(:input) do
        '   test   '
      end
      let(:expected_output) do
        'test'
      end

      it do
        expect(described_class.recursively_strip_value_whitespace!(input)).to eq(expected_output)
        expect(input).to eq(expected_output)
      end
    end

    context 'when the passed-in structure contains a frozen string' do
      let(:arr_with_frozen_string_element) do
        [
          '  string 1  '.freeze,
          '  string 2  ',
          '  string 3  '
        ]
      end

      let(:hash_with_frozen_string_value) do
        {
          'key 1' => '  string value 1  '.freeze,
          'key 2' => '  string value 2  ',
          'key 3' => '  string value 3  '
        }
      end

      context 'and the replace_frozen_strings_when_stripped param is false '\
        '(which is the default value)' do
        it 'raises an exception when a given array contains a frozen string value' do
          expect {
            described_class.recursively_strip_value_whitespace!(arr_with_frozen_string_element)
          }.to raise_error(FrozenError)
        end

        it 'raises an exception when a given hash contains a frozen string value' do
          expect {
            described_class.recursively_strip_value_whitespace!(hash_with_frozen_string_value)
          }.to raise_error(FrozenError)
        end
      end

      context 'and the replace_frozen_strings_when_stripped param is true' do
        it 'replaces a frozen array value as expected' do
          described_class.recursively_strip_value_whitespace!(
            arr_with_frozen_string_element, replace_frozen_strings_when_stripped: true
          )
          expect(arr_with_frozen_string_element[0]).to eq(arr_with_frozen_string_element[0].strip)
          expect(arr_with_frozen_string_element[0]).not_to be_frozen
        end

        it 'replaces a frozen hash value as expected' do
          described_class.recursively_strip_value_whitespace!(
            hash_with_frozen_string_value, replace_frozen_strings_when_stripped: true
          )
          expect(hash_with_frozen_string_value['key 1']).to eq(hash_with_frozen_string_value['key 1'].strip)
          expect(hash_with_frozen_string_value['key 1']).not_to be_frozen
        end
      end
    end
  end
end
