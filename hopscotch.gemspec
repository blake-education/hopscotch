# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hopscotch/version'

Gem::Specification.new do |spec|
  spec.name          = "hopscotch"
  spec.version       = Hopscotch::VERSION
  spec.authors       = ["Garrett Heinlen"]
  spec.email         = ["heinleng@gmail.com"]

  spec.summary       = %q{simplify complex business logic.}
  spec.description   = %q{Hopscotch allows us to chain together complex logic and ensure if any specific part of the chain fails, everything is rolled back to its original state.}
  spec.homepage      = "https://github.com/blake-education/hopscotch"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "https://rubygems.org"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0"
end
