# frozen_string_literal: true

require "spec_helper"

describe "User creates proposal simply", type: :system do
  include_context "with a component"
  let(:organization) { create :organization, available_locales: [:en] }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "proposals" }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let!(:scope) { create :scope, organization: organization }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:proposal_title) { "More sidewalks and less roads" }
  let(:proposal_body) { "Cities need more people, not more cars" }

  before do
    login_as user, scope: :user
  end

  context "when creating a new proposal" do
    before do
      login_as user, scope: :user
      visit_component
    end

    it "creates new proposal" do
      click_link "New proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
      select category.name["en"], from: :proposal_category
      click_link "Global scope"
      click_link scope.name["en"]
      click_link "Select"

      click_button "Continue"
      expect(page).to have_content("Publish", wait: 5)
      expect(page).to have_content("Proposal successfully published.")
    end

    # context "and draft proposal exists for current users" do
    #   let!(:draft) { create(:proposal, :draft, component: component, users: [user]) }

    #   it "redirects to edit draft" do
    #     click_link "New proposal"
    #     path = "#{main_component_path(component)}proposals/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
    #     expect(page).to have_current_path(path)
    #   end
    # end
  end
end
