module Hopscotch
  module With
    extend self
    def with(&blk)
      Definition.new(&blk)
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

      def initialize(&blk)
        @lines = []
        @nomatch = @match = ->(*args) { args }

        instance_exec(&blk)

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

      def match(&blk)
        if block_given?
          @match = blk
        else
          @match
        end
      end

      def method_missing(name, *rest)
        Val.new(name, *rest)
      end
    end
  end
end
