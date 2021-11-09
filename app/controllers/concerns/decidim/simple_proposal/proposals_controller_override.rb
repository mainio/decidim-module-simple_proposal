# frozen_string_literal: true

module Decidim
  module SimpleProposal
    module ProposalsControllerOverride
      extend ActiveSupport::Concern

      included do
        def new
          if proposal_draft.present?
            redirect_to edit_draft_proposal_path(proposal_draft, component_id: proposal_draft.component.id, question_slug: proposal_draft.component.participatory_space.slug)
          else
            enforce_permission_to :create, :proposal
            @step = :step_1
            @proposal ||= Decidim::Proposals::Proposal.new(component: current_component)
            @form = form_proposal_model
            @form.body = translated_proposal_body_template
            @form.attachment = form_attachment_new
          end
        end

        def create
          enforce_permission_to :create, :proposal
          @step = :step_1
          @form = form(Decidim::Proposals::ProposalForm).from_params(proposal_creation_params)

          @proposal = Decidim::Proposals::Proposal.new(@form.attributes.except(
            :user_group_id,
            :category_id,
            :scope_id,
            :has_address,
            :attachment,
            :body_template,
            :suggested_hashtags,
            :photos,
            :add_photos,
            :documents,
            :add_documents
          ).merge(
            component: current_component
          ))
          user_group = Decidim::UserGroup.find_by(
            organization: current_organization,
            id: params[:proposal][:user_group_id]
          )
          @proposal.add_coauthor(current_user, user_group: user_group)

          # We update these when creating proposal, but We want to call update because after that proposal becomes persisted
          # and it adds coauthor correctly.
          @proposal.update(title: { I18n.locale => @form.attributes[:title] })
          @proposal.update(body: { I18n.locale => @form.attributes[:body] })

          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update_draft.success", scope: "decidim")
              redirect_to "#{Decidim::ResourceLocatorPresenter.new(proposal).path}/preview"
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update_draft.error", scope: "decidim")
              render :new
            end
          end
        end

        # Overridden because of a core bug when the command posts the "invalid"
        # signal and when rendering the form.
        def update_draft
          enforce_permission_to :edit, :proposal, proposal: @proposal
          @step = :step_1

          @form = form_proposal_params
          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update_draft.success", scope: "decidim")
              redirect_to "#{Decidim::ResourceLocatorPresenter.new(proposal).path}/preview"
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update_draft.error", scope: "decidim")
              fix_form_photos_and_documents
              render :edit_draft
            end
          end
        end

        # Overridden because of a core bug when the command posts the "invalid"
        # signal and when rendering the form.
        def update
          enforce_permission_to :edit, :proposal, proposal: @proposal

          @form = form_proposal_params
          Decidim::Proposals::UpdateProposal.call(@form, current_user, @proposal) do
            on(:ok) do |proposal|
              flash[:notice] = I18n.t("proposals.update.success", scope: "decidim")
              redirect_to Decidim::ResourceLocatorPresenter.new(proposal).path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("proposals.update.error", scope: "decidim")
              fix_form_photos_and_documents
              render :edit
            end
          end
        end

        private

        def form_proposal_params
          form(Decidim::Proposals::ProposalForm).from_params(params)
        end

        def default_filter_params
          {
            search_text: "",
            origin: default_filter_origin_params,
            activity: "all",
            category_id: default_filter_category_params,
            state: %w(accepted evaluating state_not_published not_answered rejected),
            scope_id: default_filter_scope_params,
            related_to: "",
            type: "all"
          }
        end

        def fix_form_photos_and_documents
          return unless @form

          @form.photos = map_attachment_objects(@form.photos)
          @form.documents = map_attachment_objects(@form.documents)
        end

        # Maps the attachment objects for the proposal form in case there are errors
        # on the form when it is being saved. Without this, the form would throw
        # an exception because it expects these objects to be Attachment records.
        def map_attachment_objects(attachments)
          return attachments unless attachments.is_a?(Array)

          attachments.map do |attachment|
            if attachment.is_a?(String) || attachment.is_a?(Integer)
              Decidim::Attachment.find_by(id: attachment)
            else
              attachment
            end
          end
        end

        # TODO: Remove after feature/configurable_order_for_proposals is merged!
        def default_order
          "recent"
        end
      end
    end
  end
end
