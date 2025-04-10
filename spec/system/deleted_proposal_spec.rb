# frozen_string_literal: true

require "spec_helper"

describe "DeletedProposal" do
  let(:organization) { create(:organization, *organization_traits, available_locales: [:en]) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest_name) { "proposals" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
           manifest:,
           participatory_space: participatory_process)
  end
  let(:organization_traits) { [] }

  let!(:proposal) { create(:proposal, component:) }
  let!(:deleted_proposal) { create(:proposal, component:, deleted_at: Time.current) }

  def visit_component
    if organization_traits.include?(:secure_context)
      switch_to_secure_context_host
    else
      switch_to_host(organization.host)
    end
    page.visit main_component_path(component)
  end

  before do
    visit_component
  end

  it "index doesnt show deleted proposal" do
    expect(page).to have_content(translated(proposal.title))
    expect(page).to have_no_content(translated(deleted_proposal.title))
  end

  it "does not show deleted proposal" do
    visit resource_locator(proposal).path
    expect(page).to have_content(translated(proposal.title))
    expect do
      visit resource_locator(deleted_proposal).path
      expect(page).to have_content("this just makes sure visit is completed")
    end.to raise_error(ActionController::RoutingError)
  end
end
