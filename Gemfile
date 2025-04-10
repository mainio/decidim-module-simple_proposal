# frozen_string_literal: true

source "https://rubygems.org"

ruby RUBY_VERSION

# Inside the development app, the relative require has to be one level up, as
# the Gemfile is copied to the development_app folder (almost) as is.
base_path = File.basename(__dir__) == "development_app" ? "../" : ""
require_relative "#{base_path}lib/decidim/simple_proposal/version"

DECIDIM_VERSION = Decidim::SimpleProposal::DECIDIM_VERSION

gem "decidim", DECIDIM_VERSION
gem "decidim-simple_proposal", path: "."

gem "bootsnap", "~> 1.4"

# This is a temporary fix for: https://github.com/rails/rails/issues/54263
# Without this downgrade Activesupport will give error for missing Logger
gem "concurrent-ruby", "1.3.4"

gem "puma", ">= 5.3.1"

group :development, :test do
  gem "byebug", "~> 11.0", platform: :mri
  gem "decidim-dev", DECIDIM_VERSION
  gem "rubocop-faker"
end

group :development do
  gem "faker", "~> 2.14"
  gem "letter_opener_web", "~> 2.0"
  gem "listen", "~> 3.1"
  gem "spring", "~> 2.0"
  gem "spring-watcher-listen", "~> 2.0"
  gem "web-console", "~> 4.2"
end
