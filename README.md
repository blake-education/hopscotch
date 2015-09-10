# Hopscotch

Hopscotch allows us to chain together complex logic and ensure if any specific part of the chain fails, everything is rolled back to its original state.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hopscotch'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hopscotch

## Usage

The Hopscotch gem is made up out of 2 essential parts. Runners and Steps.

Some simple usage examples.

```ruby
# - simple lambdas steps
# - compose steps into 1 function
# - runner call function with success/failure callbacks
success_step = -> { Hopscotch::Step.success! }
fail_step = -> { Hopscotch::Step.failure!("bad") }

reduced_fn = Hopscotch::StepComposer.compose_with_error_handling(success_step, success_step, success_step)
Hopscotch::Runner.call(reduced_fn, success: -> { "success" }, failure: -> (x) { "failure: #{x}" })
# => "success"

error_reduced_fn = Hopscotch::StepComposer.compose_with_error_handling(success_step, fail_step, success_step)
Hopscotch::Runner.call(error_reduced_fn, success: -> { "success" }, failure: -> (x) { "failure: #{x}" })
# => "failure: bad"


# - simple lambdas steps
# - runner call function + compose steps inline with success/failure callbacks
success_step_1 = -> { Hopscotch::Step.success! }
success_step_2 = -> { Hopscotch::Step.success! }

Hopscotch::Runner.call(
  Hopscotch::StepComposer.call_each(success_step_1, success_step_2),
  success: -> { "success" },
  failure: -> (x) { "failure: #{x}" },
)
# => "success"


# Module method to compose multiple steps into 1 step
# - runner call composed function with success/failure callbacks
module ChainSteps
  extend self
  def call
    Hopscotch::StepComposer.call_each(
      -> { Hopscotch::Step.success! },
      -> do
        if 2.even?
          Hopscotch::Step.success!
        else
          Hopscotch::Step.failure!
        end
      end
    )
  end
end

Hopscotch::Runner.call_each(
  -> { ChainSteps.call },
  success: -> { "success" },
  failure: -> (x) { "failure: #{x}" },
)
# => "success"
```

### Runners
A runner is a pipeline to run steps and handle the success or failure of the group of them.

Runners are not meant to be the point of reuse or shared behavior. They are simply a way to run steps.

```ruby
Hopscotch::Runner.call_each(
  -> { Hopscotch::Step.success! },
  success: -> { success.call("The step was successful!", Time.now.to_i) },
  failure: failure
)
```

### Steps

A step is a function type. It can be plugged into any module/class as long as it conforms to returning `Hopscotch::Step.success!` or `Hopscotch::Step.failure!`

These two functions wrap the return value to let the runner know if the step was successful or not.

```ruby
module Service
  module AddItemToCart
    extend self

    def call(item, cart)
      if cart.add(item)
        Hopscotch::Step.success!
      else
        Hopscotch::Step.failure!
      end
    end
  end
end
```

**note** You can optionally pass in values to `success!` and `failure!` to be used outside of the step. ie: `failure!(cart.errors)`

### A typical use-case

```ruby
class UsersController < ApplicationController
  def create
    success = -> (response, time) { redirect_to root_path, notice: "#{response} - at: #{time}" }
    failure = -> { render :new }
    Workflow::CreateUser.call(params[:name], success: success, failure: failure)
  end
end

module Workflow
  module CreateUser
    extend self

    def call(name, success:, failure:)

      Hopscotch::Runner.call_each(
        -> { Service::CreateUser.call(name) },
        success: -> { success.call("Workflow::CreateUser worked!", Time.now.to_i) },
        failure: failure
      )
    end
  end
end

module Service
  module CreateUser
    extend self

    def call(name)
      if User.create(name: name)
        Hopscotch::Steps.success!
      else
        Hopscotch::Steps.failure!
      end
    end
  end
end
```

### Reusing steps

A common problem you might run into when dealing with multiple runners and steps is the need to copy 90% of a previous runner but just change 1 or 2 step calls. Let's make it happen.

Let's take an example of `Signup` runner which creates a student, and sends them an email.

```ruby
module Workflow
  module Signup
    def call(student_params, success:, failure:)
      # We make heavy use of form objects, so this is a common pattern for us
      # but you can really do what ever you want in here..
      form = Form::NewStudent.new(student_params)

      Hopscotch::Runner.call_each(
        -> { Service::CreateStudent.call(form) }, # these return `Hopscotch::Step.success!` or `Hopscotch::Step.failure!`
        -> { Service::NotifyStudent.call(form) }
        success: success,
        failure: failure
      )
    end
  end
end
```

Here's a brief example of what the services might look like.

```ruby
module Service
  module CreateStudent
    extend self

    def call(student_form)
      if student_form.valid? && student_form.save
        Hopscotch::Steps.success!
      else
        Hopscotch::Steps.failure!(student_form.errors)
      end
    end
  end
end

module Service
  module NotifyStudent
    extend self

    def call(student_form)
      if Notify::SendMail.new(student_form).deliver
        Hopscotch::Steps.success!
      else
        Hopscotch::Steps.failure!
      end
    end
  end
end
```

Here we just ensure the student is valid and persisted and then send a mailer.

All is well in love and steps. Let's assume that something in the system has to change (as it rarely does..), and we need to add a new step to the process to the runner, but only for a segmented part of our user base. Phew..

The new feature request comes in and we want to give free points to a student when they signup if they are home schooled. While we could chunk some lovely if statements into our runner or steps to do this, I prefer to create a new runner only for this particular interaction in the system. Let's start.

```ruby
module Workflow
  module SignupWithFreePoints
    def call(student_params, success:, failure:)
      form = Form::NewStudent.new(student_params)

      Hopscotch::Runner.call_each(
        -> { Service::CreateStudent.call(form) }, # this is duplication.. :(
        -> { Service::NotifyStudent.call(form) }, # this is duplication.. :(
        -> { Service::GiveFreePointsToStudent.call(form) }, # this sucker is the new one
        success: success,
        failure: failure
      )
    end
  end
end
```

While this example _could_ work, we're already duplicating code and things could easily get out of sync with the previous Signup runner. Let's say steps get removed or changed and we forget to update in both places.. bug reports will soon roll in. Let's fix this.

Here is where Steps shine. Steps can be composed to nest other steps. Let's see how we can clean up our code with a new Step that utilizes this.

```ruby
module Service
  module CreateStudentAndNotify
    extend self

    def call(student_form)
      # This will bubble up the success or failure of both of these nested steps
      # and return a success! or failure! depending on the collected results.
      Hopscotch::StepComposer.call_each(
        -> { Service::CreateStudent.call(student_form) },
        -> { Service::NotifyStudent.call(student_form) }
      )
    end
  end
end
```

What does this mean for our runner? They get simpler and allow for quick reuse! Let's see.

```ruby
module Workflow
  module Signup
    def call(student_params, success:, failure:)
      form = Form::NewStudent.new(student_params)

      Hopscotch::Runner.call_each(
        -> { Service::CreateStudentAndNotify.call(form) },
        success: success,
        failure: failure
      )
    end
  end
end

module Workflow
  module SignupWithFreePoints
    def call(student_params, success:, failure:)
      form = Form::NewStudent.new(student_params)

      Hopscotch::Runner.call_each(
        -> { Service::CreateStudentAndNotify.call(form) }, # re-use steps
        -> { Service::GiveFreePointsToStudent.call(form) }, # the new step
        success: success,
        failure: failure
      )
    end
  end
end
```

2 runners, different behavior - no duplication. It's a beauty.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hopscotch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

