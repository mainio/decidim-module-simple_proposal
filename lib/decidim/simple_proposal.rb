# frozen_string_literal: true

require_relative "simple_proposal/version"
require_relative "simple_proposal/engine"

module Decidim
  module SimpleProposal
    mattr_accessor :require_scope, default: true
  end
end
