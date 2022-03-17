# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module Admin
      # Allow admin to split proposals even it has votes or it's not official.
      module ProposalForkFormOverride
        extend ActiveSupport::Concern
        included do
          def mergeable_to_same_component
            true
          end
        end
      end
    end
  end
end
