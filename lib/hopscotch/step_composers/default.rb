module Hopscotch
  module StepComposers
    module Default
      extend self

      # `call_each` composes a list of functions into a single function
      # which it thens calls, returning the result of the composition
      #
      # Each fn should have the rough type:
      # ```
      # fn :: void -> ReturnValue
      # ```
      #
      def call_each(*fns)
        compose_with_error_handling(fns).call
      end

      # Composes a list of functions into a single function.
      #
      # *Note* that this isn't a general purpose composition.
      # *Note* a function here is anything that responds to `call` i.e. lambda or a singleton module.
      #
      def compose_with_error_handling(*fns)
        reduced_fn = fns.flatten.compact.inject do |composed, fn|
          proc do |*args|
            last_return = composed.call(*args)
            if Hopscotch::Error.error?(last_return)
              last_return
            else
              # Need to special-case no-arg lambdas, or it's going break compatibility.
              case fn.arity
              when 0 then fn.call
              else        fn.curry.call(last_return)
              end
            end
          end
        end
        reduced_fn || -> { Hopscotch::Step.success! }
      end
    end
  end
end
