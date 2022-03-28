# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module UpdateProposalOverride
      extend ActiveSupport::Concern
      included do
        private

        def photo_cleanup!
          proposal.attachments.each do |photo|
            photo_and_document_ids = form.photos.map(&:id).concat(form.documents.map(&:id))
            photo.destroy! if photo_and_document_ids.exclude? photo.id
          end
          # manually reset cached photos
          gallery_attached_to.reload
          gallery_attached_to.instance_variable_set(:@photos, nil)
        end
      end
    end
  end
end
