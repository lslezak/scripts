#! /usr/bin/env rspec

require_relative "./spec_helper"

describe Version do
  describe ".string" do
    it "returns a String" do
      expect(Version.string).to be_a(String)
    end

    it "is not empty" do
      expect(Version.string).to_not be_empty
    end

    it "contains a version number and a hexadecimal checksum" do
      expect(Version.string).to match(/\A\d+\.\d+\.\d+\s*\(\h+\)/)
    end
  end
end
