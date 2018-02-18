require 'spec_helper'

describe JsonCsv do

  it "should be a module" do
    expect(JsonCsv).to be_a Module
  end

  describe "::version" do
    it "should return the version" do
      expect(JsonCsv::version).to eq(subject::VERSION)
    end
  end

end
