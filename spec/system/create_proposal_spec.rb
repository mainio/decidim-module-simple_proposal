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
           :with_attachments_allowed_and_collaborative_drafts_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let!(:scope) { create :scope, organization: organization }
  let!(:category) { create :category, participatory_space: participatory_process }

  let(:proposal_title) { "More sidewalks and less roads" }
  let(:proposal_body) { "Cities need more people, not more cars" }

  before do
    login_as user, scope: :user
    visit_component
  end

  def fill_category_and_scope
    select category.name["en"], from: :proposal_category_id
    click_link "Global scope"
    click_link scope.name["en"]
    click_link "Select"
  end

  context "when category and scope are required" do
    before do
      allow(Decidim::SimpleProposal).to receive(:require_category).and_return(true)
      allow(Decidim::SimpleProposal).to receive(:require_scope).and_return(true)
    end

    describe "proposal creation process" do
      it "doesnt create a new proposal without category and scope" do
        click_link "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        select category.name["en"], from: :proposal_category_id
        click_button "Preview"
        expect(page).to have_css(".form-error")
        expect(page).to have_content("can't be blank")
      end

      it "creates a new proposal with a category and scope" do
        click_link "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_category_and_scope
        click_button "Preview"
        click_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
        expect(Decidim::Proposals::Proposal.last.category).to eq(category)
        expect(Decidim::Proposals::Proposal.last.scope).to eq(scope)
      end

      it "can be edited after creating a draft" do
        click_link "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        fill_category_and_scope
        click_button "Preview"
        click_link "Modify the proposal"
        fill_in :proposal_title, with: "This proposal is modified"
        click_button "Preview"
        expect(page).to have_content("This proposal is modified")
        click_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
      end
    end

    context "when draft proposal exists for current users" do
      let!(:draft) { create(:proposal, :draft, component: component, users: [user]) }

      it "can finish proposal" do
        click_link "New proposal"
        path = "#{main_component_path(component)}proposals/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
        expect(page).to have_current_path(path)

        select category.name["en"], from: :proposal_category_id
        click_link "Global scope"
        click_link scope.name["en"]
        click_link "Select"
        click_button "Preview"
        click_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
      end
    end
  end

  context "when category and scope arent required" do
    before do
      allow(Decidim::SimpleProposal).to receive(:require_category).and_return(false)
      allow(Decidim::SimpleProposal).to receive(:require_scope).and_return(false)
    end

    it "creates a new proposal without category and scope" do
      click_link "New proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
      select category.name["en"], from: :proposal_category_id
      click_button "Preview"
      click_button "Publish"
      expect(page).to have_content("Proposal successfully published.")
    end
  end

end
