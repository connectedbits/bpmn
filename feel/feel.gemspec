require_relative "lib/feel/version"

Gem::Specification.new do |spec|
  spec.name = "feel"
  spec.version = FEEL::VERSION
  spec.authors = ["Connected Bits"]
  spec.email = ["info@connectedbits.com"]

  spec.summary = "A light-weight FEEL expression evaluator in Ruby."
  spec.description = "..."
  spec.homepage    = "https://www.connectedbits.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/connectedbits/bpmn/feel"

  spec.files = Dir["{lib,doc}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "activemodel", ">= 7.0.2.3"
  spec.add_dependency "activesupport", ">= 7.0.2.3"
  spec.add_dependency "ostruct"
  spec.add_dependency "treetop", "=1.6.12" # locked as treetop made some class changes that cause: superclass mismatch for class Parser (TypeError)

  spec.add_development_dependency "rake"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "minitest-spec"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-focus"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "solargraph"
  spec.add_development_dependency "treetop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-doc"
end
