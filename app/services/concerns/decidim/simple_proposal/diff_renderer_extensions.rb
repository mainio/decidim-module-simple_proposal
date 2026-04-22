# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module DiffRendererExtensions
      extend ActiveSupport::Concern

      included do
        private

        # Lists which attributes will be diffable and how they should be rendered.
        def attribute_types
          {
            title: :i18n,
            body: :i18n,
            decidim_category_id: :category,
            decidim_scope_id: :scope,
            address: :string,
            latitude: :string,
            longitude: :string,
            decidim_proposals_proposal_state_id: :state,
            answer: :i18n
          }
        end

        def parse_values(attribute, values)
          values = [amended_previous_value(attribute), values[1]] if proposal&.emendation?

          case attribute
          when :body
            values.map { |value| normalize_line_endings(value) }
          when :answer
            sanitize_values(values)
          else
            values
          end
        end

        def sanitize_values(values)
          values.map do |value|
            next "" if value.nil?

            if value.is_a?(Hash)
              value.select { |_, text| text.present? }
                   .transform_values { |text| ActionView::Base.full_sanitizer.sanitize(text).strip }
            else
              value.to_s
            end
          end
        end
      end
    end
  end
end
