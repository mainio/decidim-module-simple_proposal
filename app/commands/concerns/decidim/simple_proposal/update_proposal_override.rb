# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module UpdateProposalOverride
      extend ActiveSupport::Concern
      included do
        def call
          return broadcast(:invalid) if invalid?

          if process_attachments?
            build_attachments
            return broadcast(:invalid) if attachments_invalid?
          end

          transaction do
            if @proposal.draft?
              update_draft
            else
              update_proposal
            end

            document_cleanup!

            create_attachments(first_weight: first_attachment_weight) if @form.add_documents.any?
          end

          broadcast(:ok, proposal)
        end

        private

        def create_attachments(first_weight: 0)
          weight = first_weight
          # Add the weights first to the old document
          @form.documents.each do |document|
            document.update!(weight:)
            weight += 1
          end
          @documents.map! do |document|
            document.weight = weight
            document.attached_to = documents_attached_to
            document.save!
            weight += 1
            @form.documents << document
          end
        end

        def first_attachment_weight
          return 1 if proposal.attachments.count.zero?

          proposal.attachments.count
        end
      end
    end
  end
end
