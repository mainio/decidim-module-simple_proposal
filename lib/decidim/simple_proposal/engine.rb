# frozen_string_literal: true

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      config.to_prepare do
        Decidim::Proposals::ProposalsController.include ProposalsControllerOverride
        Decidim::Proposals::ProposalForm.include ProposalFormOverride
        Decidim::Proposals::ProposalMCell.include ProposalMCellOverride
      end
    end
  end
end
