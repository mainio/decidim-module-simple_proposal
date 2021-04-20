# frozen_string_literal: true

require "spec_helper"

describe "User creates proposal simply", type: :system do
  let(:organization) { create :organization, *organization_traits, available_locales: [:en] }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "proposals" }
  let(:manifest) { Decidim.find_component_manifest(manifest_name) }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
           manifest: manifest,
           participatory_space: participatory_process)
  end
  let(:organization_traits) { [] }

  let(:proposal_title) { ::Faker::Lorem.paragraph }
  let(:proposal_body) { ::Faker::Lorem.paragraph }

  def visit_component
    if organization_traits.include?(:secure_context)
      switch_to_secure_context_host
    else
      switch_to_host(organization.host)
    end
    page.visit main_component_path(component)
  end

  before do
    login_as user, scope: :user
    visit_component
  end

  context "when category and scope are required" do
    before do
      allow(Decidim::SimpleProposal).to receive(:require_category).and_return(true)
      allow(Decidim::SimpleProposal).to receive(:require_scope).and_return(true)
    end

    describe "proposal creation process without scope and category" do
      it "creates a new proposal without a category and scope" do
        click_link "New proposal"
        fill_in :proposal_title, with: proposal_title
        fill_in :proposal_body, with: proposal_body
        click_button "Preview"
        click_button "Publish"
        expect(page).to have_content("Proposal successfully published.")
        expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
        expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
      end
    end

    context "when there is a scope and category" do
      let!(:scope) { create :scope, organization: organization }
      let!(:category) { create :category, participatory_space: participatory_process }

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

        context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
          it "can add image" do
            click_link "New proposal"
            fill_in :proposal_title, with: proposal_title
            fill_in :proposal_body, with: proposal_body
            fill_category_and_scope
            attach_file(:proposal_add_photos, Decidim::Dev.asset("city.jpeg"))
            click_button "Preview"
            click_button "Publish"
            expect(page).to have_content("Proposal successfully published.")
          end
        end
      end

      context "when draft proposal exists for current users" do
        let!(:draft) { create(:proposal, :draft, component: component, users: [user]) }

        before do
          click_link "New proposal"
          path = "#{main_component_path(component)}proposals/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
          expect(page).to have_current_path(path)
          fill_category_and_scope
        end

        it "can finish proposal" do
          click_button "Preview"
          click_button "Publish"
          expect(page).to have_content("Proposal successfully published.")
        end

        context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
          it "shows error message when image is malicious" do
            attach_file(:proposal_add_photos, Decidim::Dev.asset("malicious.jpg"))
            click_button "Preview"
            expect(page).to have_content("There was a problem saving the proposal")
          end
        end
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
      click_button "Preview"
      click_button "Publish"
      expect(page).to have_content("Proposal successfully published.")
    end
  end

  def fill_category_and_scope
    select category.name["en"], from: :proposal_category_id
    click_link "Global scope"
    click_link scope.name["en"]
    click_link "Select"
  end
end
