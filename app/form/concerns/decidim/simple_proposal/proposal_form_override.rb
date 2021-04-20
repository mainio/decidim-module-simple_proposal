# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalFormOverride
      extend ActiveSupport::Concern
      included do
        _validators.delete(:category)
        _validators.delete(:scope)

        _validate_callbacks.each do |callback|
          callback.raw_filter.attributes.delete :category if callback.raw_filter.respond_to? :attributes
          callback.raw_filter.attributes.delete :scope if callback.raw_filter.respond_to? :attributes
        end

        validates :category_id, presence: true, if: ->(form) { form.require_category? }
        validates :scope_id, presence: true, if: ->(form) { form.require_scope? }
        validate :check_category
        validate :check_scope

        def require_category?
          Decidim::SimpleProposal.require_category && Decidim::Scope.count.positive?
        end

        def require_scope?
          Decidim::SimpleProposal.require_scope && categories.count.positive?
        end

        private

        def check_category
          errors.add(:category, :blank) if category_id.blank? && require_category?
        end

        def check_scope
          errors.add(:scope, :blank) if scope_id.blank? && require_scope?
        end
      end
    end
  end
end
