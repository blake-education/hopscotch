module Hopscotch
  module Runners
    module Default
      extend self

      # Execute `fn` within an `ActiveRecord` transaction.
      #
      # Rough types:
      # ```
      # fn :: void -> ReturnValue
      # failure :: value -> NilClass
      #
      # success :: value -> NilClass
      # # or
      # success :: void -> NilClass
      # ```
      #
      # If `fn` returns an `ErrorValue`, roll back the transaction and call `failure` with the unwrapped error `value`.
      # Otherwise commit the transaction and call success.
      def call(fn, failure:, success:)
        error = nil
        result = nil

        if failure.arity != 1
          raise ArgumentError, "failure lambda requires an error value argument."
        end

        ActiveRecord::Base.transaction do
          result = fn.call

          if Hopscotch::Error.error?(result)
            error = result
            raise ActiveRecord::Rollback
          end
        end

        if error
          failure.call(error.value)
        else
          success.arity == 1 ? success.call(result) : success.call
        end
      end

      # `call_each` composes a list of functions into a single function
      # which it then passes along to a `call` to perform the workflow logic.
      #
      # Each fn should have the rough type:
      # ```
      # fn :: void -> ReturnValue
      # ```
      #
      def call_each(*fns, failure:, success:)
        call ::Hopscotch::StepComposers::Default.compose_with_error_handling(*fns), failure: failure, success: success
      end
    end
  end
end
