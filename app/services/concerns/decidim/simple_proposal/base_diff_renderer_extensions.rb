# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module BaseDiffRendererExtensions
      extend ActiveSupport::Concern

      included do
        def parse_i18n_changeset(attribute, values, type, diff)
          return diff unless values.last.is_a?(Hash)

          sanitizer = ActionView::Base.full_sanitizer

          (values.last.keys - ["machine_translations"]).each do |locale, _value|
            first_value = values.first.try(:[], locale)
            last_value = values.last.try(:[], locale)

            first_value = sanitizer.sanitize(first_value.to_s).strip
            last_value = sanitizer.sanitize(last_value.to_s).strip

            next if first_value == last_value

            attribute_locale = `:"#{attribute}_#{locale}"`
            diff.update(
              attribute_locale => {
                type:,
                label: generate_i18n_label(attribute, locale),
                old_value: first_value,
                new_value: last_value
              }
            )
          end

          return diff unless values.last.has_key?("machine_translations")

          values.last.fetch("machine_translations").each_key do |locale, _value|
            next unless I18n.available_locales.include?(locale.to_sym)

            first_value = values.first.try(:[], "machine_translations").try(:[], locale)
            last_value = values.last.try(:[], "machine_translations").try(:[], locale)

            first_value = sanitizer.sanitize(first_value.to_s).strip
            last_value = sanitizer.sanitize(last_value.to_s).strip

            attribute_locale = :"#{attribute}_machine_translations_#{locale}"

            diff.update(
              attribute_locale => {
                type:,
                label: generate_i18n_label(attribute, locale, "decidim.machine_translations.automatic"),
                old_value: first_value,
                new_value: last_value
              }
            )
          end

          diff
        end
      end
    end
  end
end
