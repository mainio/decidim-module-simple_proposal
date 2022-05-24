# frozen_string_literal: true

require "spec_helper"

describe "User edits proposals", type: :system do
  include_context "with a component"
  let(:organization) { create :organization, available_locales: [:en] }
  let(:participatory_process) { create :participatory_process, :with_steps, organization: organization }
  let(:manifest_name) { "proposals" }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
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
      click_link translated(proposal.title)
      click_link "Edit idea"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
    end

    it "can be edited" do
      click_button "Save"
      expect(page).to have_content("Idea successfully updated")
      expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
      expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
    end

    context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
      it "can add image" do
        attach_file(:proposal_add_photos, Decidim::Dev.asset("city.jpeg"))
        click_button "Save"
        expect(page).to have_content("Idea successfully updated")
      end

      it "can add images" do
        attach_file(:proposal_add_photos, Decidim::Dev.asset("city.jpeg"))
        click_button "Save"
        click_link "Edit idea"
        attach_file(:proposal_add_photos, Decidim::Dev.asset("city2.jpeg"))
        click_button "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(Decidim::Proposals::Proposal.last.attachments.count).to eq(2)
      end

      it "can add pdf document" do
        attach_file(:proposal_add_photos, Decidim::Dev.asset("Exampledocument.pdf"))
        click_button "Save"
        expect(page).to have_content("Idea successfully updated")
      end
    end

    context "when proposal has attachment" do
      let!(:proposal) { create(:proposal, users: [user], component: component) }
      let!(:attachment) { create(:attachment, title: { "en" => filename }, file: file, attached_to: proposal, weight: 0) }

      context "when proposal has pdf attachment" do
        let(:filename) { "Exampledocument.pdf" }
        let(:file) { Decidim::Dev.test_file(filename, "application/pdf") }

        before do
          login_as user, scope: :user
          visit_component
          click_link translated(proposal.title)
        end

        it "can remove document attachment" do
          click_link "Edit idea"

          find("[title='Delete Document']").click
          click_button "Save"
          expect(page).to have_css(".callout.success")
          expect(page).not_to have_content("Related documents")
          expect(page).not_to have_link(filename)
          expect(Decidim::Proposals::Proposal.find(proposal.id).attachments).to be_empty
        end
      end

      context "when proposal has card image" do
        let(:filename) { "city.jpeg" }
        let(:file) { Decidim::Dev.test_file(filename, "image/jpeg") }

        before do
          login_as user, scope: :user

          settings = component.settings
          settings.comments_enabled = false
          component.update(settings: settings)

          visit_component
          click_link translated(proposal.title)
        end

        it "can remove card image" do
          click_link "Edit idea"
          find("[title='Delete Image']").click
          click_button "Save"
          expect(page).to have_css(".callout.success")
          expect(page).not_to have_content("RELATED IMAGES")
          expect(page).not_to have_link(filename)
          expect(Decidim::Proposals::Proposal.find(proposal.id).attachments).to be_empty
        end

        it "can set new card image" do
          click_link "Edit idea"
          attach_file(:proposal_add_photos, Decidim::Dev.asset("city2.jpeg"))
          click_button "Save"
          expect(page).to have_css(".callout.success")
          page.execute_script "window.scrollBy(0,10000)"

          expect(page).to have_content("RELATED IMAGES")

          created_proposal = Decidim::Proposals::Proposal.find(proposal.id)
          expect(created_proposal.attachments.count).to eq(2)
          expect(created_proposal.photos.select { |p| p.title == { "en" => "city2.jpeg" } && p.weight == 0 }.count).to eq(1)
          expect(created_proposal.photos.select { |p| p.title == { "en" => filename } && p.weight == 1 }.count).to eq(1)
        end
      end
    end

    context "when proposal has card image and document image" do
      let!(:proposal) { create(:proposal, users: [user], component: component) }

      let!(:card_image) { create(:attachment, title: { "en" => filename }, file: file, attached_to: proposal, weight: 0) }
      let(:filename) { "city.jpeg" }
      let(:file) { Decidim::Dev.test_file(filename, "image/jpeg") }

      let!(:document) { create(:attachment, title: { "en" => filename2 }, file: file2, attached_to: proposal, weight: 1) }
      let(:filename2) { "city2.jpeg" }
      let(:file2) { Decidim::Dev.test_file(filename2, "image/jpeg") }

      before do
        login_as user, scope: :user
        visit_component
        click_link translated(proposal.title)
      end

      it "attachments are in different sections" do
        click_link "Edit idea"
        # page.execute_script "window.scrollBy(0,10000)"
        expect(page).to have_selector("#photo-#{card_image.id}[name='proposal[photos][]']", visible: :hidden)
        expect(page).to have_selector("#document-#{document.id}[name='proposal[documents][]']", visible: :hidden)
      end
    end
  end
end
