require 'spec_helper'
require 'json_csv/array_notation'

describe JsonCsv::ArrayNotation do
  let(:bracket_header) {
    'some-thing[0].with[1].brackets[2]'
  }
  let(:dash_header) {
    'some-thing-0.with-1.brackets-2'
  }

  context ".bracket_header_to_dash_header" do
    it "converts as expected" do
      expect(described_class.bracket_header_to_dash_header(bracket_header)).to eq(dash_header)
    end
  end

  context ".dash_header_to_bracket_header" do
    it "converts as expected" do
      expect(described_class.dash_header_to_bracket_header(dash_header)).to eq(bracket_header)
    end
  end


  context ".raise_error_if_invalid_array_notation_value!" do
    let(:error_class) { ArgumentError }
    let(:invalid_array_notation) { 'not valid' }
    it "raises an error for an invalid value" do
      expect{ described_class.raise_error_if_invalid_array_notation_value!(error_class, invalid_array_notation) }.to raise_error(error_class)
    end
    it "does not raise an error for a valid value" do
      expect{ described_class.raise_error_if_invalid_array_notation_value!(error_class, JsonCsv::ArrayNotation::BRACKETS) }.not_to raise_error
      expect{ described_class.raise_error_if_invalid_array_notation_value!(error_class, JsonCsv::ArrayNotation::DASH) }.not_to raise_error
    end
  end

end
