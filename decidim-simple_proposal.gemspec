# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "decidim/simple_proposal/version"

Gem::Specification.new do |spec|
  spec.name = "decidim-simple_proposal"
  spec.version = Decidim::SimpleProposal::VERSION
  spec.required_ruby_version = ">= 3.1"
  spec.authors = ["Eero Lahdenperä"]
  spec.email = ["info@mainiotech.fi"]
  spec.metadata = {
    "rubygems_mfa_required" => "true"
  }

  spec.summary = "Makes creation of a proposal simple"
  spec.description = "Remove compare and complete phases from proposal creation."
  spec.homepage = "https://github.com/mainio/decidim-module-simple_proposal"
  spec.license = "AGPL-3.0"

  spec.files = Dir[
    "{app,config,lib}/**/*",
    "LICENSE-AGPLv3.txt",
    "Rakefile",
    "README.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "decidim-core", Decidim::SimpleProposal::DECIDIM_VERSION
  spec.add_dependency "decidim-proposals", Decidim::SimpleProposal::DECIDIM_VERSION
end
