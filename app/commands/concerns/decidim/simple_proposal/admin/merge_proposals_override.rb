# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      module MergeProposalsOverride
        extend ActiveSupport::Concern

        included do
          def call
            form.valid?
            return broadcast(:invalid) unless form.valid?

            if process_attachments?
              build_attachments
              return broadcast(:invalid) if attachments_invalid?
            end

            transaction do
              merged_proposals
            end
            broadcast(:ok, @merge_proposal)
          end

          private

          def merged_proposals
            @merged_proposal = create_new_proposal

            link_proposals = (proposals_to_link + form.proposals).uniq

            @merged_proposal.link_resources(link_proposals, "copied_from_component")

            form.proposals.each do |proposal|
              proposal.update(merged_at: Time.current)
            end

            move_comments_to_merged_proposal

            @attached_to = @merged_proposal

            create_attachments(first_weight: first_attachment_weight) if process_attachments?
            link_author_meeting if form.created_in_meeting?
            notify_author
          end

          def create_new_proposal
            original_proposal = form.proposals.min_by(&:id)

            proposal = Decidim::Proposals::ProposalBuilder.copy(
              original_proposal,
              author: nil,
              action_user: form.current_user,
              extra_attributes: {
                component: form.target_component,
                title: form.title,
                body: form.body.compact_blank.merge("machine_translations" => merged_machine_translations)
              },
              skip_link: true
            )

            merge_authors(proposal, original_proposal)
            proposal
          end

          def merge_authors(proposal, original_proposal)
            form.proposals.sort_by(&:id).each do |form_proposal|
              form_proposal.authors.each do |author|
                proposal.add_coauthor(author) unless proposal.authors.include?(author)
              end
            end

            proposal.add_coauthor(original_proposal.organization) unless proposal.authors.include?(original_proposal.organization)
          end

          def move_comments_to_merged_proposal
            form.proposals.each do |form_proposal|
              form_proposal.comments.each do |comment|
                comment.update(commentable: @merged_proposal)
                comment.update(root_commentable: @merged_proposal)
              end
            end
          end

          def merged_machine_translations
            merged = {}
            form.proposals.sort_by(&:id).each do |form_proposal|
              (form_proposal.body["machine_translations"] || {}).each do |locale, translation|
                merged[locale] = merged[locale].present? ? "#{merged[locale]}\n\n#{translation}" : translation
              end
            end
            merged
          end
        end
      end
    end
  end
end
