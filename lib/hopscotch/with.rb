require 'hopscotch/with/matching'
require 'hopscotch/with/nomatch'
require 'hopscotch/with/execution'
require 'hopscotch/with/loop_runner'

module Hopscotch
  module With
    extend self

    def with(blocks: [], &blk)
      definition = Definition.new(blocks: blocks, &blk)
      Execution.execute(definition)
    end

    class Var < Struct.new(:name, :value_path)
      def to_s
        name.to_s
      end
    end
    class Pattern < Struct.new(:parts)
      def to_s
        "pat(#{ parts.map(&:to_s).join(',') })"
      end
    end
    class Computation < Struct.new(:computation, :args)
      def to_s
        "#{computation.to_s}( #{ args.map(&:to_s).join(',')} )"
      end
    end

    class Line < Struct.new(:callsite, :pattern, :computation)
      def []=(*args)
        self.computation = args.pop
        self.pattern = Pattern.new(args)
      end

      def to_s
        "#{pattern} = #{computation}"
      end
    end

    class Definition
      attr_reader :lines

      def initialize(blocks: [], &blk)
        @lines = []
        @nomatch = @final_match = ->(*args) { args }

        blocks = [blocks, blk].flatten.compact

        blocks.each do |blk|
          @current_block_self = blk.binding.eval("self")
          instance_exec(&blk)
          @current_block_self = nil
        end

        if @unwrap_nomatch
          @nomatch = Nomatch.method(:unwrap_nomatch)
        end
      end

      def match
        # TODO record callsite (caller)
        Line.new(caller.first).tap do |l|
          @lines << l
        end
      end

      def call(computation, *args)
        Computation.new(computation, args)
      end

      # XXX
      def unwrap_nomatch
        @unwrap_nomatch = true
      end

      def nomatch(&blk)
        if block_given?
          @nomatch = blk
        else
          @nomatch
        end
      end

      def final_match(&blk)
        if block_given?
          @final_match = blk
        else
          @final_match
        end
      end

      def method_missing(name, *rest)
        Var.new(name, *rest)
      end
    end
  end
end
