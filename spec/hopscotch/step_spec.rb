require 'spec_helper'

describe Hopscotch::Step do
  module UnderTest
    extend Hopscotch::Step
  end

  it 'makes value successy' do
    expect(Hopscotch::Error.success?(UnderTest.success!(:a))).to eq(true)
  end

  it 'makes value errory' do
    expect(Hopscotch::Error.error?(UnderTest.failure!(:a))).to eq(true)
  end
end
