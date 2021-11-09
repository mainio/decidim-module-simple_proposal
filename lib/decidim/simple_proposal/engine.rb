# frozen_string_literal: true

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      initializer "decidim_proposals.overrides" do |app|
        app.config.to_prepare do
          Decidim::Proposals::ProposalsController.include Decidim::SimpleProposal::ProposalsControllerOverride
          Decidim::Proposals::ProposalForm.include Decidim::SimpleProposal::ProposalFormOverride
          Decidim::ScopesHelper.include Decidim::SimpleProposal::ScopesHelperOverride
        end
      end
    end
  end
end
