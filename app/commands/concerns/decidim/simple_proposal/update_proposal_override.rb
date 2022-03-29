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

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            if @proposal.draft?
              update_draft
            else
              update_proposal
            end

            photo_cleanup!
            document_cleanup!

            create_photos if process_gallery?
            create_attachments(first_weight: first_attachment_weight) if @form.add_documents.any?
          end

          broadcast(:ok, proposal)
        end

        private

        def create_attachments(first_weight: 0)
          weight = first_weight
          # Add the weights first to the old document
          @form.documents.each do |document|
            document.update!(weight: weight)
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

        def photo_cleanup!
          proposal.attachments.each do |photo|
            photo_and_document_ids = form.photos.map(&:id).concat(form.documents.map(&:id))
            photo.destroy! if photo_and_document_ids.exclude? photo.id
          end
          # manually reset cached photos
          gallery_attached_to.reload
          gallery_attached_to.instance_variable_set(:@photos, nil)
        end

        def first_attachment_weight
          return 1 if proposal.photos.count.zero?

          proposal.photos.count
        end

        def create_photos
          proposal.photos.each do |photo|
            next unless photo.weight.zero?

            photo.weight = 1
            photo.save!
          end

          @gallery.map! do |photo|
            photo.attached_to = proposal
            photo.weight = 0
            photo.save!
            @form.photos << photo
          end
        end
      end
    end
  end
end
