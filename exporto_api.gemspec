# frozen_string_literal: true

require_relative "lib/exporto_api/version"

Gem::Specification.new do |spec|
  spec.name = "exporto_api"
  spec.version = ExportoAPI::VERSION
  spec.authors = ["PostCo"]
  spec.email = ["engineering@postco.co"]

  spec.summary = "Rails-independent Ruby client for the Exporto API"
  spec.description = "A small Ruby client foundation for integrating with Exporto without depending on Rails."
  spec.homepage = "https://github.com/PostCo/exporto_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) { Dir["lib/**/*.rb", "README.md"] }.sort
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.1", "< 9"
  spec.add_dependency "faraday", ">= 2.0", "< 3"
  spec.add_dependency "zeitwerk", ">= 2.6", "< 3"

  spec.add_development_dependency "bundler", ">= 2.5", "< 5"
  spec.add_development_dependency "minitest", ">= 5.20", "< 7"
  spec.add_development_dependency "rake", ">= 13.1", "< 14"
end
