require "hopscotch/version"

require "hopscotch/error"
require "hopscotch/step"
require "hopscotch/step_composers/default"
require "hopscotch/runners/default"

module Hopscotch
  module Runner
    extend self

    def call(fn, failure:, success:)
      Hopscotch::Runners::Default.call(fn, failure: failure, success: success)
    end

    def call_each(*fns, failure:, success:)
      Hopscotch::Runners::Default.call_each(*fns, failure: failure, success: success)
    end
  end
end
