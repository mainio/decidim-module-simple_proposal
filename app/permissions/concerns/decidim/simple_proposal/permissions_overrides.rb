# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module PermissionsOverrides
      extend ActiveSupport::Concern

      included do
        def can_withdraw_proposal?
          toggle_allow(proposal && author?)
        end

        def author?
          proposal.authored_by?(user) || proposal.authors.one? && proposal.authors.first.is_a?(Decidim::Organization) && user.admin?
        end
      end
    end
  end
end
