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

  let(:proposal_title) { ::Faker::Lorem.paragraph }
  let(:proposal_body) { ::Faker::Lorem.paragraph }

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
      expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
      expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
    end

    context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
      it "can add image" do
        attach_file(:proposal_add_photos, Decidim::Dev.asset("city.jpeg"))
        click_button "Save"
        expect(page).to have_content("Proposal successfully updated")
      end
    end
  end
end
