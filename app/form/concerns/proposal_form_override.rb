# frozen_string_literal: true

module ProposalFormOverride
  extend ActiveSupport::Concern
  included do
    _validators.delete(:category)
    _validators.delete(:scope)

    _validate_callbacks.each do |callback|
      callback.raw_filter.attributes.delete :category if callback.raw_filter.respond_to? :attributes
      callback.raw_filter.attributes.delete :scope if callback.raw_filter.respond_to? :attributes
    end

    validates :category, presence: Decidim::SimpleProposal.require_category
    validates :scope, presence: Decidim::SimpleProposal.require_scope
  end
end
