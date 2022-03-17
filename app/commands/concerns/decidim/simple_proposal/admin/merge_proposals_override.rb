# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      module MergeProposalsOverride
        extend ActiveSupport::Concern
        included do
          def create_new_proposal
            original_proposal = form.proposals.first

            proposal = Decidim::Proposals::ProposalBuilder.copy(
              original_proposal,
              author: nil,
              action_user: form.current_user,
              extra_attributes: {
                component: form.target_component
              },
              skip_link: true
            )

            # Proposal builder's copy just copies authors from first proposal
            form.proposals.slice(1...).each do |p|
              p.authors.each do |a|
                proposal.add_coauthor(a) unless proposal.authors.include?(a)
              end
            end
            proposal.add_coauthor(original_proposal.organization) unless proposal.authors.include?(original_proposal.organization)
            proposal
          end
        end
      end
    end
  end
end
