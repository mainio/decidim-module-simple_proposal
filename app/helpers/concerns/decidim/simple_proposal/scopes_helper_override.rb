# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ScopesHelperOverride
      extend ActiveSupport::Concern
      included do
        def scopes_picker_field(form, name, root: false, options: { checkboxes_on_top: true })
          options.merge!(selected: form.scope_id) if form.try(:scope_id)
          options.merge!(selected: form.settings.scope_id) if form.try(:settings).try(:scope_id)
          form.select(name, simple_scope_options(root: root, options: options), include_blank: t("decidim.scopes.prompt"))
        end

        private

        def simple_scope_options(root: false, options: {})
          scopes_arrray = []
          roots = root ? root.children : ancestors
          roots.each do |ancestor|
            children_after_parent(ancestor, scopes_arrray, "")
          end
          selected = options.has_key?(:selected) ? options[:selected] : params.dig(:filter, :decidim_scope_id)
          options_for_select(scopes_arrray, selected)
        end

        def ancestors
          @ancestors ||= Decidim::Scope.where(parent_id: nil)
        end

        def children_after_parent(ancestor, array, prefix)
          array << ["#{prefix} #{translated_attribute(ancestor.name)}", ancestor.id]
          ancestor.children.each do |child|
            children_after_parent(child, array, "#{prefix}-")
          end
        end
      end
    end
  end
end
