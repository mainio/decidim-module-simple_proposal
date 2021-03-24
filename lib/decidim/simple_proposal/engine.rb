# frozen_string_literal: true

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      initializer "decidim.proposals_controller_override" do
        Decidim::Proposals::ProposalsController.include Decidim::SimpleProposal::ProposalsControllerOverride
      end

      initializer "decidim.proposals.form_override" do
        Decidim::Proposals::ProposalForm.include Decidim::SimpleProposal::ProposalFormOverride
      end

      initializer "decidim.proposals_mcell_override" do
        Decidim::Proposals::ProposalMCell.include Decidim::SimpleProposal::ProposalMCellOverride
      end
    end
  end
end
