require_relative "lib/bpmn/version"

Gem::Specification.new do |spec|
  spec.name        = "bpmn"
  spec.version     = BPMN::VERSION
  spec.authors     = ["Connected Bits"]
  spec.email       = ["info@connectedbits.com"]
  spec.homepage    = "https://www.connectedbits.com"
  spec.summary     = "A BPMN workflow engine in Ruby"
  spec.description = "BPMN is a workflow gem for Ruby applications based on the BPMN standard. It executes business processes and rules defined in a modeler."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/connectedbits/process_pilot"

  spec.files = Dir["{lib,doc}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "dmn", ">= 0.0.3"

  spec.add_dependency "activemodel", ">= 7.0.2.3"
  spec.add_dependency "xmlhasher", "~> 1.0.7"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
  spec.add_development_dependency "minitest-spec"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-focus"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "solargraph"
  spec.add_development_dependency "simplecov"
end
