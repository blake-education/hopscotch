module Hopscotch
  module Step
    extend self

    def success!(value = true)
      value
    end

    def failure!(value = false)
      Hopscotch::Error.to_error(value)
    end
  end
end
