require "hopscotch/version"

require "hopscotch/error"
require "hopscotch/step"
require "hopscotch/step_composers/default"
require "hopscotch/runners/default"

module Hopscotch
  class << self
    attr_writer :logger

    # Defaults to the ruby logger, override to your preferred logger in your app
    # example
    # ```
    # Hopscotch.logger = Rails.logger
    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end

  module Runner
    extend self

    def call(fn, failure:, success:)
      Hopscotch::Runners::Default.call(fn, failure: failure, success: success)
    end

    def call_each(*fns, failure:, success:)
      Hopscotch::Runners::Default.call_each(*fns, failure: failure, success: success)
    end
  end

  module StepComposer
    extend self

    def call_each(*fns)
      Hopscotch::StepComposers::Default.call_each(fns)
    end

    def compose_with_error_handling(*fns)
      Hopscotch::StepComposers::Default.compose_with_error_handling(fns)
    end
  end
end
