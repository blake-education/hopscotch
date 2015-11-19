require 'spec_helper'

describe Hopscotch::StepComposers::Default do
  describe '.compose_with_error_handling' do
    it 'composes lambdas' do
      handled = []

      r = subject.compose_with_error_handling(
        -> { handled << :a; "first" },
        [
          -> { handled << :b; "array[0]" },
          nil,
          -> { handled << :c; "array[1]" },
        ],
        -> { handled << :d; "last" }
      ).call

      expect(handled).to eq([:a, :b, :c, :d])
      expect(r).to eq("last")
    end

    it 'composes error handling' do
      handled = []
      r = subject.compose_with_error_handling(
        -> { handled << :a; "first" },
        -> { handled << :b; Hopscotch::ErrorValue.new("error") },
        -> { handled << :c; "last" }
      ).call

      expect(handled).to eq([:a, :b])
      expect(r).to be_instance_of(Hopscotch::ErrorValue)
      expect(r.value).to eq("error")
    end

    it 'returns a success lambda if composition flattens to nil' do
      r = subject.compose_with_error_handling([[], [nil], nil])
      expect(r.call).to eq(true)
    end

    it 'allows values to be passed between steps' do
      r = subject.compose_with_error_handling(
        ->            { 123 },                     # No args
        -> (number)   { number * 2 },              # One arg
        -> (*numbers) { numbers.map {|n| n + 1 } } # Many args
      ).call
      expect(r).to eq([247])
    end

    it 'uses currying for 1+ argument steps' do
      r = subject.compose_with_error_handling(
        -> (number) { number * 2     }, # One arg
        -> (n, z)   { [n + 1, z - 1] }  # Two args; curried.
      ).call(111)
      expect(r).to be_a(Proc)
      expect(r.call(111)).to eq([223, 110])
    end

    it 'allows short pipelines of value-passing steps' do
      effects = []
      r = subject.compose_with_error_handling(
        [
          ->   { 123 },
          -> n { n * 2 },
          -> n { effects << n },
        ],
        -> { "ignores return value from previous step; returns a value that is ignored" },
        -> { effects << "Sent Email" },
        -> { "result" }
      ).call
      expect(r).to eq("result")
      expect(effects).to eq([246, "Sent Email"])
    end
  end

  describe '.call_each' do
    it 'allows nesting of services' do
      handled = []

      subject.call_each(
        -> { handled << :a },
        -> do
          subject.call_each(
            -> { handled << :b_a },
            -> { handled << :b_b },
          )
        end,
        -> { handled << :c }
      )
      expect(handled).to eq([:a, :b_a, :b_b, :c])
    end
  end
end
