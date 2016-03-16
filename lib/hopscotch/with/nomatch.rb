module Hopscotch
  module With
    module Nomatch
      extend self

      def nomatch?(returned)
        Array === returned && returned.first == :nomatch
      end

      def flatten(returned)
        # TODO handle exception
        if nomatch?(returned)
          _nomatch,message,next_nomatch = *returned

          [message, *flatten(next_nomatch)]
        else
          returned
        end
      end

      def pop_if_nomatch(returned)
        if nomatch?(returned)
          unwrap(returned)
        else
          returned
        end
      end

      def wrap_return_as_error(returned, line)
        if Array === returned && returned.first == :err
          returned
        else

          [:nomatch, "failed to match pattern #{line.pattern} = #{line.computation} (was #{returned} = #{line.computation})", returned]
        end
      end

      def unwrap(returned)
        if nomatch?(returned)
          returned[2]
        else
          returned
        end
      end

      # version for using as a lambda
      def unwrap_splat(*returned)
        unwrap(returned)
      end
    end
  end
end
