# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalsControllerOverride
      extend ActiveSupport::Concern

      included do
        def index
          if component_settings.participatory_texts_enabled?
            @proposals = ::Decidim::Proposals::Proposal
                         .where(component: current_component, deleted_at: nil)
                         .published
                         .not_hidden
                         .only_amendables
                         .includes(:category, :scope)
                         .order(position: :asc)
            render "decidim/proposals/proposals/participatory_texts/participatory_text"
          else
            @base_query = search
                          .result
                          .where(deleted_at: nil)
                          .published
                          .not_hidden

            @proposals = @base_query.includes(:component, :coauthorships)
            @all_geocoded_proposals = @base_query.geocoded

            @voted_proposals = if current_user
                                 ::Decidim::Proposals::ProposalVote.where(
                                   author: current_user,
                                   proposal: @proposals.pluck(:id)
                                 ).pluck(:decidim_proposal_id)
                               else
                                 []
                               end
            @proposals = paginate(@proposals)
            @proposals = reorder(@proposals)
          end
        end

        private

        def default_filter_params
          {
            search_text_cont: "",
            with_any_origin: nil,
            activity: "all",
            with_any_category: nil,
            with_any_state: %w(accepted evaluating state_not_published not_answered rejected),
            with_any_scope: nil,
            related_to: "",
            type: "all"
          }
        end

        def can_show_proposal?
          return false if @proposal&.deleted_at.present?
          return true if @proposal&.amendable? || current_user&.admin?

          ::Decidim::Proposals::Proposal.only_visible_emendations_for(current_user, current_component).published.include?(@proposal)
        end
      end
    end
  end
end
