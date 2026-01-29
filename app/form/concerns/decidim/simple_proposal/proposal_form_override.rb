# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalFormOverride
      extend ActiveSupport::Concern
      included do
        _validators.delete(:category)
        _validators.delete(:scope)

        _validate_callbacks.each do |callback|
          callback.filter.attributes.delete :category if callback.filter.respond_to? :attributes
          callback.filter.attributes.delete :scope if callback.filter.respond_to? :attributes
        end

        validates :category_id, presence: true, if: ->(form) { form.require_category? }
        validates :scope_id, presence: true, if: ->(form) { form.require_scope? }
        validate :check_category
        validate :check_scope

        def map_model(model)
          self.title = translated_attribute(model.title)
          self.body = translated_attribute(model.body)
          @suggested_hashtags = Decidim::ContentRenderers::HashtagRenderer.new(body).extra_hashtags.map(&:name).map(&:downcase)

          self.user_group_id = model.user_groups.first&.id
          self.category_id = model.categorization.decidim_category_id if model.categorization

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
          current_component.settings.mandatory_category && categories_enabled?
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
