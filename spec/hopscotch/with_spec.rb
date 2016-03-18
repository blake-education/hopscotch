require 'spec_helper'

class Object
  def tapp(tag=nil)
    print "#{tag}=" if tag
    tap { pp self }
  end
end

describe Hopscotch::With do
  it "works" do
    input_word = "hey"

    result = Hopscotch::With.with do
      match[:ok, word ] = call(->(word) { [:ok, word] }, input_word)
      match[:ok, word2] = call(->(word) { [:ok, word.reverse] }, word)
    end

    expect(result).to eq [:ok, "yeh"]
  end

  it "doesn't match" do
    result = Hopscotch::With.with do
      match[:ok] = call(->(word) { [:err] })
    end

    expect(result[0]).to eq :err
    expect(result[1]).to be_instance_of String
  end

  it "calls nomatch" do
    result = Hopscotch::With.with do
      match[:ok] = call(-> { [:err] })

      nomatch do |_err, *things|
        [:nomatch, *things]
      end
    end

    expect(result).to eq [:nomatch]
  end

  it "calls final_match" do
    input_word = "hey"

    result = Hopscotch::With.with do
      match[:ok, word ] = call(->(word) { [:ok, word] }, input_word)
      match[:ok, word2] = call(->(word) { [:ok, word.reverse] }, word)

      final_match do |_ok, word|
        word.reverse
      end
    end

    expect(result).to eq "hey"
  end

  it "can use multiple blocks" do
    input_word = "hey"

    another_block = -> {
      match[:ok, word] = call(->(word) { [:ok, "xx#{word}zz"] }, input_word)
    }

    result = Hopscotch::With.with(blocks: another_block) do
      match[:ok, word ] = call(->(word) { [:ok, word] }, word)
      match[:ok, word2] = call(->(word) { [:ok, word.reverse] }, word)
    end

    expect(result).to eq [:ok, "zzyehxx"]
  end

  it "works naturally with nesting" do
    input_word = "hey"

    nested = ->(input_word) {
      Hopscotch::With.with do
        match[:ok, word ] = call(->(word) { [:ok, word.reverse] }, input_word)
      end
    }

    result = Hopscotch::With.with do
      match[:ok, word ] = call(nested, input_word)
      match[:ok, word2] = call(->(word) { [:ok, word.reverse] }, word)
    end

    expect(result).to eq [:ok, "hey"]
  end

  context Hopscotch::With::Definition do
    it "does the definition" do
      defn = Hopscotch::With::Definition.new do
        match[:ok, word] = call(->(word) { [:ok, word] }, :hey)
        match[:ok      ] = call(->(word) { [:ok, word] }, word)
      end

      expect(defn.lines.size).to eq(2)
    end
  end

  context Hopscotch::With::Pattern do
  end

  context Hopscotch::With::Execution do
  end
end
