# frozen_string_literal: true

require "decidim/concerns/simple_proposal/autocomplete_override"

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      config.to_prepare do
        Decidim::Proposals::ProposalsController.include Decidim::SimpleProposal::ProposalsControllerOverride
        Decidim::Proposals::ProposalForm.include Decidim::SimpleProposal::ProposalFormOverride
        Decidim::ScopesHelper.include Decidim::SimpleProposal::ScopesHelperOverride
        Decidim::Map::Autocomplete::FormBuilder.include Decidim::SimpleProposal::AutocompleteOverride
      end
    end
  end
end
