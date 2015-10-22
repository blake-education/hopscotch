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
      # The composed function and each constituent function have the same signature, roughly:
      # ```
      # fn :: void -> ReturnValue
      # ```
      #
      # *Note* that `void` is used here to mean "takes no arguments".
      # This is a dead giveaway that functions of this type signature will have side effects.
      #
      def compose_with_error_handling(*fns)
        reduced_fn = fns.flatten.compact.inject do |composed, fn|
          -> do
            last_return = composed.call
            if Hopscotch::Error.error?(last_return)
              last_return
            else
              fn.call
            end
          end
        end
        reduced_fn || -> { Hopscotch::Step.success! }
      end
    end
  end
end
