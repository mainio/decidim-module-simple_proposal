# frozen_string_literal: true

# Fix nil (which will come later NaN) coordinate values
module Decidim
  module SimpleProposal
    module AutocompleteOverride
      extend ActiveSupport::Concern

      included do
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        def geocoding_field(attribute, options = {}, geocoding_options = {})
          @autocomplete_utility ||= Decidim::Map.autocomplete(
            organization: @template.current_organization
          )
          return text_field(attribute, options) unless @autocomplete_utility

          # Decidim::Map::Autocomplete::Builder
          builder = @autocomplete_utility.create_builder(
            @template,
            geocoding_options
          )

          unless @template.snippets.any?(:geocoding)
            @template.snippets.add(:geocoding, builder.stylesheet_snippets)
            @template.snippets.add(:geocoding, builder.javascript_snippets)

            # This will display the snippets in the <head> part of the page.
            @template.snippets.add(:head, @template.snippets.for(:geocoding))
          end

          options[:value] ||= object.send(attribute) if object.respond_to?(attribute)
          if object.respond_to?(:latitude) && object.respond_to?(:longitude) && object.latitude.present? && object.longitude.present?
            point = [object.latitude, object.longitude]
            options["data-coordinates"] ||= point.join(",")
          end

          field(attribute, options) do |opts|
            builder.geocoding_field(
              @object_name,
              attribute,
              opts
            )
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/PerceivedComplexity
      end
    end
  end
end
