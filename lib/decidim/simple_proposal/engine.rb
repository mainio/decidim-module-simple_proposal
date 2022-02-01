# frozen_string_literal: true

require "decidim/concerns/simple_proposal/autocomplete_override"

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      initializer "decidim_proposals.overrides" do |app|
        app.config.to_prepare do
          Decidim::Proposals::ProposalsController.include Decidim::SimpleProposal::ProposalsControllerOverride
          Decidim::Proposals::ProposalForm.include Decidim::SimpleProposal::ProposalFormOverride
          Decidim::ScopesHelper.include Decidim::SimpleProposal::ScopesHelperOverride

          # Remove after https://github.com/decidim/decidim/pull/8762
          Decidim::Map::Autocomplete::FormBuilder.include Decidim::SimpleProposal::AutocompleteOverride
        end
      end
    end
  end
end
