# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      module ProposalsControllerOverride
        extend ActiveSupport::Concern

        included do
          def collection
            @collection ||= ::Decidim::Proposals::Proposal.where(component: current_component, deleted_at: nil).not_hidden.published
          end
        end
      end
    end
  end
end
