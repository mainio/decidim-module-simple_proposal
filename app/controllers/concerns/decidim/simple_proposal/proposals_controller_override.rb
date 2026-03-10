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

        def new
          if proposal_draft.present?
            redirect_to edit_draft_proposal_path(proposal_draft, component_id: proposal_draft.component.id, question_slug: proposal_draft.component.participatory_space.slug)
          else
            enforce_permission_to :create, :proposal
            @step = Decidim::Proposals::ProposalsController::STEP1
            @proposal ||= Decidim::Proposals::Proposal.new(component: current_component)
            @form = form_proposal_model
            @form.body = translated_proposal_body_template
            @form.attachment = form_attachment_new
          end
        end

        def create
          enforce_permission_to :create, :proposal
          @step = Decidim::Proposals::ProposalsController::STEP1
          @form = form(Decidim::Proposals::ProposalForm).from_params(proposal_creation_params)

          category_id = params[:proposal][:category_id]
          scope_id = params[:proposal][:scope_id]

          Decidim::Proposals::CreateProposal.call(@form, current_user) do
            on(:ok) do |proposal|
              proposal.category = Category.find(category_id) if category_id.present?
              proposal.scope = Scope.find(scope_id) if scope_id.present?
              proposal.save!

              flash[:notice] = I18n.t("proposals.create.success", scope: "decidim")

              redirect_to "#{Decidim::ResourceLocatorPresenter.new(proposal).path}/preview"
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.create.error", scope: "decidim")
              render :new
            end
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
