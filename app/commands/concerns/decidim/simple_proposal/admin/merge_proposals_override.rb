# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      module MergeProposalsOverride
        extend ActiveSupport::Concern
        included do
          private

          def merge_proposals
            transaction do
              merged_proposal = create_new_proposal
              merged_proposal.link_resources(proposals_to_link, "copied_from_component")
              form.proposals.each do |proposal|
                proposal.update(deleted_at: Time.current)
              end
              merged_proposal
            end
          end

          def create_new_proposal
            original_proposal = form.proposals.min_by(&:id)

            proposal = Decidim::Proposals::ProposalBuilder.copy(
              original_proposal,
              author: nil,
              action_user: form.current_user,
              extra_attributes: {
                component: form.target_component
              }
            )

            proposal = simply_merge_proposals(proposal)

            proposal.add_coauthor(original_proposal.organization) unless proposal.authors.include?(original_proposal.organization)
            proposal
          end

          def simply_merge_proposals(proposal)
            replace_body = {}
            form.proposals.sort_by(&:id).each do |form_proposal|
              form_proposal.authors.each do |author|
                proposal.add_coauthor(author) unless proposal.authors.include?(author)
              end

              replace_body = simply_merge_bodies(form_proposal, replace_body)

              form_proposal.comments.each do |comment|
                comment.update(commentable: proposal)
                comment.update(root_commentable: proposal)
              end
            end

            proposal.body = replace_body
            proposal.save(validate: false)
            proposal
          end

          def simply_merge_bodies(form_proposal, replace_body)
            form_proposal.body.keys.each do |key|
              if key == "machine_translations"
                replace_body = simply_merge_machine_translations(form_proposal, key, replace_body)
              elsif form_proposal.body[key].is_a?(String)
                replace_body[key] = "" unless replace_body.has_key?(key)
                replace_body[key] += "\n\n" if replace_body[key].present?
                replace_body[key] += form_proposal.body[key]
              end
            end
            replace_body
          end

          def simply_merge_machine_translations(form_proposal, key, replace_body)
            form_proposal.body[key].each do |k|
              replace_body[key] = {} if replace_body[key].nil?
              language = k[0]
              translation = k[1]
              replace_body[key][language] = "" unless replace_body[key].has_key?(language)
              replace_body[key][language] += "\n\n" if replace_body[key][language].present?
              replace_body[key][language] += translation
            end

            replace_body
          end
        end
      end
    end
  end
end
