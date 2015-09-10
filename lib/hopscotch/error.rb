module Hopscotch
  # `ErrorValue` denotes an error.
  #
  # ```
  # data ReturnValue = ErrorValue value | value
  # ```
  #
  # In the context of Ruby and `Workflows` this means:
  # - a value represents an error iff it is an `ErrorValue`
  # - otherwise the value represents success
  #
  class ErrorValue < Struct.new(:value)
  end

  # `Error` provides helper functions for working with ErrorValue (and thus ReturnValue)
  module Error
    extend self

    # Returns `true` if `e` is an error
    def error?(e)
      ErrorValue === e
    end

    # Returns `false` if `e` is an error
    def success?(e)
      ! error?(e)
    end

    # Convert `e` into a value representing an error, if required.
    def to_error(e)
      case e
      when ErrorValue
        e
      else
        ErrorValue.new(e)
      end
    end
  end
end
