# frozen_string_literal: true

module Decidim
  module SimpleProposal
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::SimpleProposal

      if Decidim.module_installed?(:privacy)
        # Fix incompatibility with the privacy module. The privacy module sets
        # itself as the first priority when loading view paths which would break
        # the functionality in this module overriding some of the same views in
        # proposals.
        initializer "decidim_privacy.prepend_view_path", after: "decidim_privacy.prepend_view_path" do
          config.after_initialize do
            # Append the engine view path **BEFORE** the privacy module's view
            # path in order to take priority over that module.
            paths = []
            ActionController::Base.view_paths.paths.each do |resolver|
              if resolver.path.starts_with?("#{Decidim::Privacy::Engine.root}/app/views")
                # Inject before privacy.
                paths << "#{Decidim::SimpleProposal::Engine.root}/app/views"
              end

              paths << resolver
            end
            ActionController::Base.view_paths = paths
          end
        end
      end

      initializer "decidim_proposals.overrides" do |app|
        app.config.to_prepare do
          Decidim::Proposals::ProposalsController.include Decidim::SimpleProposal::ProposalsControllerOverride
          Decidim::Proposals::ProposalForm.include Decidim::SimpleProposal::ProposalFormOverride
          Decidim::ScopesHelper.include Decidim::SimpleProposal::ScopesHelperOverride

          Decidim::Proposals::Admin::ProposalsController.include Decidim::SimpleProposal::Admin::ProposalsControllerOverride

          # Allow admins to split & merge proposals more freely
          Decidim::Proposals::Admin::ProposalsForkForm.include Decidim::SimpleProposal::Admin::ProposalForkFormOverride
          Decidim::Proposals::Admin::SplitProposals.include Decidim::SimpleProposal::Admin::SplitProposalsOverride
          Decidim::Proposals::Admin::MergeProposals.include Decidim::SimpleProposal::Admin::MergeProposalsOverride
          Decidim::Proposals::Admin::Permissions.include Decidim::SimpleProposal::Admin::PermissionOverrides

          # Fix attachments (images as documents), should not be needed after #8681
          Decidim::Proposals::UpdateProposal.include Decidim::SimpleProposal::UpdateProposalOverride
        end
      end
    end
  end
end
