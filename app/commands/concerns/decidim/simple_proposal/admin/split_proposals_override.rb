# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      module SplitProposalsOverride
        extend ActiveSupport::Concern
        included do
          def create_proposal(original_proposal)
            split_proposal = Decidim::Proposals::ProposalBuilder.copy(
              original_proposal,
              author: nil, # It should copy authors from original proposal
              action_user: form.current_user,
              extra_attributes: {
                component: form.target_component
              },
              skip_link: true
            )

            proposals_to_link = links_for(original_proposal)
            split_proposal.link_resources(proposals_to_link, "copied_from_component")

            # So that we know that proposal is split
            [original_proposal, split_proposal].each do |proposal|
              proposal.add_coauthor(original_proposal.organization) unless proposal.authors.include?(original_proposal.organization)
            end
            split_proposal
          end
        end
      end
    end
  end
end
