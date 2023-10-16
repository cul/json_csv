# frozen_string_literal: true

require 'spec_helper'

describe JsonCsv do
  it 'is a module' do
    expect(described_class).to be_a Module
  end

  describe '::version' do
    it 'returns the version' do
      expect(described_class.version).to eq(described_class::VERSION)
    end
  end
end
