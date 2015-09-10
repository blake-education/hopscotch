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

A simple example.

```
λ bin/console
irb(main):001:0> module ActiveRecord
irb(main):002:1>   class Rollback < StandardError; end
irb(main):003:1>   class Base
irb(main):004:2>     def self.transaction(&blk)
irb(main):005:3>       begin
irb(main):006:4*         yield
irb(main):007:4>       rescue Rollback
irb(main):008:4>       end
irb(main):009:3>     end
irb(main):010:2>   end
irb(main):011:1> end
=> :transaction
irb(main):012:0> Hopscotch::Runner.call_each(-> { "abc" }, success: -> { puts "success it worked" }, failure: -> (x) { puts "123" })
success it worked
=> nil
irb(main):013:0> Hopscotch::Runner.call_each(-> { Hopscotch::Error.to_error("abc") }, success: -> { puts "success it worked" }, failure: -> (x) { puts "it failed!" })
it failed!
=> nil
```

### Runners
A runner is a pipeline to run steos and handle the success or failure of the group of them.

Runners are not meant to be the point of reuse or shared behavior. They are simply a way to run steps.

If you find yourself needing to make a new runner that follows mostly what a previous runner is doing - you should make use of the steps - not the runner.

```ruby
module Workflow
  module Example
    extend self
    # `name` is a value from the outside (controller, or rake task, etc.)
    #
    # `success` and `failure` are lambda's passed in from the outside.
    # One or the other will get called when the workflow is finished depending on the status of the group of services
    #
    # You can pass any number of values back to the success/failure callbacks like any other ruby lambdas.
    #
    def call(name, success:, failure:)
      Hopscotch::Runner.call_each(
        -> { Service::Abc.call(name) }, # we will go into more detail about this below
        success: -> { success.call("Workflow example worked!", Time.now.to_i) },
        failure: failure
      )
    end
  end
end
```

**note**: example of a controller calling a workflow:

```ruby
#### Example of calling the Workflow from a controller
class UsersController < ApplicationController
  def create
    success = -> (response, time) { redirect_to root_path, notice: "#{response} - at: #{time}" }
    failure = -> { render :new }
    Workflow::Example.call(params[:name], success: success, failure: failure)
  end
end
```

### Steps
A step is a module that has 1 public function, `#call`.

It must conform to the convention and return either `success!` or `failure!`. These two functions wrap the return value to let the workflow know if the service was successful or not.

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

**note** You can optionally pass in values to `success!` and `failure!` to be used outside of the service. ie: `failure!(cart.errors)`


## Reusing steps

A common problem you might run into when dealing with multiple runners and steps is the need to copy 90% of a previous runner but just change 1 or 2 step calls. Let's make it happen.


Let's take an example of `Signup` workflow which creates a student, and sends them an email.

```ruby
module Workflow
  module Signup
    def call(student_params, success:, failure:)
      # We make heavy use of form objects, so this is a common pattern for us
      # but you can really do what ever you want in here..
      form = Form::NewStudent.new(student_params)

      Hopscotch::Runner.call_each(
        -> { Service::CreateStudent.call(form) },
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

While this example _could_ work, we're already duplicating code and things could easily get out of sync with the previous Signup workflow. Let's say steps get removed or changed and we forget to update in both places.. bug reports will soon roll in. Let's fix this.

Here is where services comes to shine. Services are able to nest other services. Let's see how we can clean up our code with a new Service that utilizes this.

```ruby
module Service
  module CreateStudentAndNotify
    extend self

    def call(student_form)
      # This will bubble up the success or failure of both of these nested services
      # and return a success! or failure! depending on the collected results.
      Hopscotch::StepComposers::Default.call_each(
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
        -> { Service::CreateStudentAndNotify.call(form) },
        -> { Service::GiveFreePointsToStudent.call(form) },
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

