require 'spec_helper'
require 'json_csv'

describe JsonCsv do

  it "responds to expected API methods" do
    expect(described_class).to respond_to(:json_hash_to_flat_csv_row_hash)
    expect(described_class).to respond_to(:create_csv_for_json_records)
    expect(described_class).to respond_to(:csv_file_to_hierarchical_json_hash)
  end

end
