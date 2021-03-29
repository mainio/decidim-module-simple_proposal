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

  let(:proposal_title) { "This proposal has now new title" }
  let(:proposal_body) { "This proposal has now new body" }

  before do
    allow(Decidim::SimpleProposal).to receive(:require_category).and_return(false)
    allow(Decidim::SimpleProposal).to receive(:require_scope).and_return(false)
  end

  context "when user has proposal" do
    let!(:proposal) { create(:proposal, users: [user], component: component) }

    before do
      login_as user, scope: :user
      visit_component
      click_link proposal.title["en"]
      click_link "Edit proposal"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
    end

    it "can be edited" do
      click_button "Save"
      expect(page).to have_content("Proposal successfully updated")
    end

    it "can add image" do
      attach_file(
        :proposal_add_photos,
        assetti("testpicture.jpg")
      )
      click_button "Save"
      expect(page).to have_content("Proposal successfully updated")
    end

    def assetti(name)
      File.expand_path(File.join(__dir__, "..", "..", "spec", "fixtures", "files", name))
    end
  end
end
