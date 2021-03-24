# frozen_string_literal: true

module ProposalMCellOverride
  extend ActiveSupport::Concern

  included do
    def description
      return strip_tags(body).gsub(/\n/, "<br/>") if options[:full_description]

      strip_tags(body).truncate(100, separator: /\s/)
    end
  end
end
