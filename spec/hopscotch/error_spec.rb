require 'spec_helper'

describe Hopscotch::Error do
  let(:error) { Hopscotch::ErrorValue.new("abc") }

  describe "#error?" do
    it "any value does not return an error type" do
      expect(Hopscotch::Error.error?(true)).to eq false
      expect(Hopscotch::Error.error?(5)).to eq false
      expect(Hopscotch::Error.error?("abc")).to eq false
    end

    it "error values return an error type" do
      expect(Hopscotch::Error.error?(error)).to eq true
    end
  end

  describe "#success?" do
    it "Returns `false` if `e` is an error" do
      expect(Hopscotch::Error.success?(true)).to eq true
      expect(Hopscotch::Error.success?(5)).to eq true
      expect(Hopscotch::Error.success?("abc")).to eq true

      expect(Hopscotch::Error.success?(error)).to eq false
    end
  end

  describe "#to_error" do
    it "wraps a value in an ErrorValue if necessary" do
      expect(Hopscotch::Error.to_error(true)).to eq Hopscotch::ErrorValue.new(true)
      expect(Hopscotch::Error.to_error("abc")).to eq Hopscotch::ErrorValue.new("abc")
    end
  end
end
