# frozen_string_literal: true

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

    it 'raises an error for non-Hash or non-Array input' do
      expect { described_class.recursively_remove_blank_fields!('not a hash or array') }.to raise_error(ArgumentError)
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

      it do
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
  end
end
