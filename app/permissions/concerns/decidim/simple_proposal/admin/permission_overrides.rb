# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      # Allow admins to edit proposals
      module PermissionOverrides
        extend ActiveSupport::Concern
        included do
          def admin_edition_is_available?
            return false unless proposal

            proposal.official? || proposal.official_meeting? || proposal.authors.any? { |p| p.is_a?(Decidim::Organization) }
          end
        end
      end
    end
  end
end
