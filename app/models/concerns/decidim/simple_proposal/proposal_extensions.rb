# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalExtensions
      extend ActiveSupport::Concern
      included do
        def withdrawable_by?(user)
          user && !withdrawn? && author?(user) && !copied_from_other_component?
        end

        def author?(user)
          authored_by?(user) || authors.one? && authors.first.is_a?(Decidim::Organization) && user.admin?
        end
      end
    end
  end
end
