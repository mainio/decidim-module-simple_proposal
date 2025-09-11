# frozen_string_literal: true

module Decidim
  module SimpleProposal
    # Removes the etiquette validator from the proposal form.
    module ProposalWizardCreateStepFormOverride
      extend ActiveSupport::Concern

      included do
        _validators[:title].delete_if { |val| val.is_a?(EtiquetteValidator) }
        _validators[:body].delete_if { |val| val.is_a?(EtiquetteValidator) }

        _validate_callbacks.each do |callback|
          next unless callback.raw_filter.is_a?(EtiquetteValidator)
          next unless callback.raw_filter.respond_to?(:attributes)

          callback.raw_filter.attributes.delete(:title)
          callback.raw_filter.attributes.delete(:body)
        end
      end
    end
  end
end
