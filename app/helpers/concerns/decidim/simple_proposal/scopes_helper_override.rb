# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ScopesHelperOverride
      extend ActiveSupport::Concern
      included do
        def scopes_picker_field(form, name, root: false, options: { checkboxes_on_top: true })
          selected = selected_scope(form, name)
          options.merge!(selected:) if selected
          form.select(name, simple_scope_options(root:, options:), include_blank: t("decidim.scopes.prompt"))
        end

        private

        def selected_scope(form, attribute)
          selected = form.object.try(attribute)
          selected = selected.values.first if selected.is_a?(Hash)
          selected = selected.first if selected.is_a?(Array)
          return selected.id if selected.is_a?(Decidim::Scope)

          selected
        end

        def simple_scope_options(root: false, options: {})
          scopes_array = []
          roots = root ? root.children : Decidim::Scope.where(parent_id: nil)
          roots.each do |ancestor|
            children_after_parent(ancestor, scopes_array, "")
          end
          # Add the root value if there are no scopes since it is important for
          # some admin forms (e.g. during budgets proposal import). Otherwise a
          # scope cannot be selected in case there are no children.
          scopes_array << [translated_attribute(root.name), root.id] if root.present? && scopes_array.empty?
          selected = options.has_key?(:selected) ? options[:selected] : params.dig(:filter, :decidim_scope_id)
          options_for_select(scopes_array, selected)
        end

        def ancestors
          @ancestors ||= Decidim::Scope.where(parent_id: nil)
        end

        def children_after_parent(ancestor, array, prefix)
          array << ["#{prefix.empty? ? "" : "#{prefix} "}#{translated_attribute(ancestor.name)}", ancestor.id]
          ancestor.children.each do |child|
            children_after_parent(child, array, "#{prefix}-")
          end
        end
      end
    end
  end
end
