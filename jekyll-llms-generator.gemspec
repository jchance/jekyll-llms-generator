# frozen_string_literal: true

require_relative "lib/jekyll-llms-generator/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-llms-generator"
  spec.version       = JekyllLlmsGenerator::VERSION
  spec.authors       = ["Jason Chance"]
  spec.email         = ["jason@jasonchance.com"]

  spec.summary       = "Automatically generate an llms.txt file for your Jekyll site."
  spec.description   = "jekyll-llms-generator is a Jekyll generator plugin that builds a standards-compliant llms.txt file from your site's posts, collections, and pages so AI language models can efficiently discover your content."
  spec.homepage      = "https://github.com/jchance/jekyll-llms-txt"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir["{lib}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.7", "< 5.0"
end
