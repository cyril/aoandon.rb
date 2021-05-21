# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "aoandon"
  spec.version       = File.read("VERSION.semver").chomp
  spec.author        = "Cyril Kato"
  spec.email         = "contact@cyril.email"
  spec.summary       = "Minimalist network intrusion detection system (NIDS)."
  spec.description   = "Aoandon (青行燈) is a minimalist network intrusion detection system (NIDS)."
  spec.homepage      = "https://github.com/cyril/aoandon.rb"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")
  spec.license       = "MIT"
  spec.files         = Dir["LICENSE.md", "README.md", "bin/aoandon", "lib/**/*"]

  spec.add_dependency "ruby-pcap", "~> 0.7"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop-md"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-thread_safety"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "yard"
end
