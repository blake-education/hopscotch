require 'spec_helper'

# mock out ActiveRecord
module ActiveRecord
  class Rollback < StandardError; end
  class Base
    def self.transaction(&blk)
      begin
        yield
      rescue Rollback
      end
    end
  end
end

describe Hopscotch::Runners::Default do
  context ".call" do
    let(:messages) { [] }

    let(:successful_fn) { -> { :success } }
    let(:failure_fn) { -> { Hopscotch::ErrorValue.new(:failed) } }

    let(:success) { ->(v) { messages << v } }
    let(:success_no_arg) { -> { messages << :success_no_arg } }
    let(:failure) { ->(v) { messages << v } }
    let(:invalid_failure) { -> { } }

    it "runs a successful workflow, with success result" do
      subject.call(successful_fn, success: success, failure: failure)
      expect(messages).to eq([:success])
    end

    it "runs a successful workflow, without success result" do
      subject.call(successful_fn, success: success_no_arg, failure: failure)
      expect(messages).to eq([:success_no_arg])
    end

    it "runs an unsuccessful workflow" do
      subject.call(failure_fn, success: success, failure: failure)
      expect(messages).to eq([:failed])
    end

    it "throws an exception when the failure lambda does not contain a first argument" do
      expect { subject.call(failure_fn, success: success, failure: invalid_failure) }.to raise_error(ArgumentError)
    end
  end

  context ".call_each" do
    let(:messages) { [] }
    let(:calls) { [] }

    let(:successful_fn) { ->{ calls << :success; :success } }
    let(:failure_fn) { ->{ calls << :failed; Hopscotch::ErrorValue.new(:failed) } }

    let(:success) { ->(v) { messages << v } }
    let(:failure) { ->(v) { messages << v } }

    it "runs a successful workflow" do
      subject.call_each(
        successful_fn,
        successful_fn,
        successful_fn,
        success: success, failure: failure)

      expect(calls).to eq([:success, :success, :success])
      expect(messages).to eq([:success])
    end

    it "runs an unsuccessful workflow" do
      subject.call_each(
        successful_fn,
        failure_fn,
        successful_fn,
        success: success, failure: failure)

      expect(calls).to eq([:success, :failed])
      expect(messages).to eq([:failed])
    end
  end
end
