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

        def map_model(model)
          super

          body = translated_attribute(model.body)
          @suggested_hashtags = Decidim::ContentRenderers::HashtagRenderer.new(body).extra_hashtags.map(&:name).map(&:downcase)

          # The scope attribute is with different key (decidim_scope_id), so it
          # has to be manually mapped.
          self.scope_id = model.scope.id if model.scope

          self.documents = model.attachments
        end

        def categories_enabled?
          categories&.any?
        end

        def scopes_enabled?
          current_component.scopes_enabled? && current_component.has_subscopes?
        end

        def require_category?
          Decidim::SimpleProposal.require_category && categories_enabled?
        end

        def require_scope?
          Decidim::SimpleProposal.require_scope && scopes_enabled?
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
