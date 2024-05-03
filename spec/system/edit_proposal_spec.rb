# frozen_string_literal: true

require "spec_helper"

describe "User edits proposals" do
  include_context "with a component"
  let(:organization) { create(:organization, available_locales: [:en]) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization:) }
  let(:manifest_name) { "proposals" }
  let!(:user) { create(:user, :confirmed, organization:) }
  let!(:component) do
    create(:proposal_component,
           :with_creation_enabled,
           :with_attachments_allowed,
           manifest:,
           participatory_space: participatory_process)
  end

  let(:proposal_title) { Faker::Lorem.paragraph }
  let(:proposal_body) { Faker::Lorem.paragraph }

  before do
    allow(Decidim::SimpleProposal).to receive_messages(require_category: false, require_scope: false)
  end

  context "when user has proposal" do
    let!(:proposal) { create(:proposal, users: [user], component:) }

    before do
      login_as user, scope: :user
      visit_component
      click_on translated(proposal.title)
      click_on "Edit idea"
      fill_in :proposal_title, with: proposal_title
      fill_in :proposal_body, with: proposal_body
    end

    it "can be edited" do
      click_link_or_button "Save"
      expect(page).to have_content("Idea successfully updated")
      expect(Decidim::Proposals::Proposal.last.title["en"]).to eq(proposal_title)
      expect(Decidim::Proposals::Proposal.last.body["en"]).to eq(proposal_body)
    end

    context "when uploading a file", processing_uploads_for: Decidim::AttachmentUploader do
      it "can add image" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
        click_link_or_button "Save"
        expect(page).to have_content("Idea successfully updated")
      end

      it "can add images" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city.jpeg"))
        click_link_or_button "Save"
        click_on "Edit idea"
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city2.jpeg"), remove_before: true)
        click_link_or_button "Save"
        expect(page).to have_content("Idea successfully updated")
        expect(Decidim::Proposals::Proposal.last.attachments.count).to eq(1)
      end

      it "can add pdf document" do
        dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("Exampledocument.pdf"))
        click_link_or_button "Save"
        expect(page).to have_content("Idea successfully updated")
      end
    end

    context "when proposal has attachment" do
      let!(:proposal) { create(:proposal, users: [user], component:) }
      let!(:attachment) { create(:attachment, title: { "en" => filename }, file:, attached_to: proposal, weight: 0) }

      context "when proposal has pdf attachment" do
        let(:filename) { "Exampledocument.pdf" }
        let(:file) { Decidim::Dev.test_file(filename, "application/pdf") }

        before do
          login_as user, scope: :user
          visit_component
          click_on translated(proposal.title)
        end

        it "can remove document attachment" do
          click_on "Edit idea"

          click_link_or_button "Edit documents"
          within ".upload-modal" do
            click_link_or_button("Remove")
            click_link_or_button "Next"
          end

          click_link_or_button "Save"
          expect(page).to have_css(".flash.success")
          expect(page).to have_no_content("Related documents")
          expect(page).to have_no_link(filename)
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
          component.update(settings:)

          visit_component
          click_on translated(proposal.title), match: :first
        end

        it "can remove card image" do
          click_on "Edit idea"
          scroll_to(0, 500)
          click_link_or_button "Edit documents"
          within ".upload-modal" do
            click_link_or_button("Remove")
            click_link_or_button "Next"
          end

          click_link_or_button "Save"
          expect(page).to have_css(".flash.success")
          expect(page).to have_no_content("RELATED IMAGES")
          expect(page).to have_no_link(filename)
          expect(Decidim::Proposals::Proposal.find(proposal.id).attachments).to be_empty
        end

        it "can set new card image" do
          click_on "Edit idea"
          dynamically_attach_file(:proposal_documents, Decidim::Dev.asset("city2.jpeg"), remove_before: true)

          click_link_or_button "Save"
          expect(page).to have_css(".flash.success")
          page.execute_script "window.scrollBy(0,10000)"

          expect(page).to have_content("Images")

          created_proposal = Decidim::Proposals::Proposal.find(proposal.id)
          expect(created_proposal.attachments.count).to eq(1)
          expect(created_proposal.attachments.select { |p| p.title == { "en" => "city2.jpeg" } && p.weight == 1 }.count).to eq(1)
        end
      end
    end

    context "when proposal has card image and document image" do
      let!(:proposal) { create(:proposal, users: [user], component:) }

      let!(:card_image) { create(:attachment, title: { "en" => filename }, file:, attached_to: proposal, weight: 0) }
      let(:filename) { "city.jpeg" }
      let(:file) { Decidim::Dev.test_file(filename, "image/jpeg") }

      let!(:document) { create(:attachment, title: { "en" => filename2 }, file: file2, attached_to: proposal, weight: 1) }
      let(:filename2) { "city2.jpeg" }
      let(:file2) { Decidim::Dev.test_file(filename2, "image/jpeg") }

      before do
        login_as user, scope: :user
        visit_component
        click_on translated(proposal.title), match: :first
      end

      it "attachments are in different sections" do
        click_on "Edit idea"
        page.execute_script "window.scrollBy(0,10000)"
        expect(page).to have_css(".attachment-details[data-filename='#{filename}']")
        expect(page).to have_css(".attachment-details[data-filename='#{filename2}']")
      end
    end
  end
end
