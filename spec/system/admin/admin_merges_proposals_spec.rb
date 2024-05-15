# frozen_string_literal: true

require "spec_helper"

describe "Admin merges proposals" do
  let(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }

  let(:author) { create(:user, :confirmed, organization:) }
  let(:another_author) { create(:user, :confirmed, organization:) }

  let(:proposal) { create(:proposal, component:, users: authors) }
  let(:authors) { [author] }

  let(:another_proposal) { create(:proposal, component:, users: other_authors) }
  let(:other_authors) { [another_author] }

  include_context "when managing a component as an admin"

  describe "merge proposals" do
    before do
      proposal
      another_proposal
    end

    it "creates new proposal and marks existing proposals deleted" do
      expect(proposal.id).to be < another_proposal.id
      visit current_path
      merge_proposals([proposal, another_proposal])
      expect(page).to have_css(".flash.success")
      expect(page).to have_content(translated(proposal.title))
      expect(Decidim::Proposals::Proposal.find(proposal.id).deleted_at).to be_between(10.seconds.ago, Time.current)
      expect(Decidim::Proposals::Proposal.find(another_proposal.id).deleted_at).to be_between(10.seconds.ago, Time.current)
      merge_proposal = Decidim::Proposals::Proposal.last
      expect(merge_proposal.deleted_at).to be_nil
      expect(merge_proposal.body["en"]).to eq("#{proposal.body["en"]}\n\n#{another_proposal.body["en"]}")
      expect(merge_proposal.authors.count).to eq(3)
      expect(merge_proposal.authors).to include(author, another_author, organization)
      expect(page).to have_css(".action-icon.action-icon--edit-proposal", count: 1)
      expect(page).to have_css("tr[data-id='#{merge_proposal.id}']")
      expect(page).to have_no_css("tr[data-id='#{proposal.id}']")
      expect(page).to have_no_css("tr[data-id='#{another_proposal.id}']")
    end

    it "links new proposal to deleted proposals" do
      visit current_path
      merge_proposals([proposal, another_proposal])
      expect(page).to have_css(".flash.success")
      linked_proposals = Decidim::Proposals::Proposal.last.linked_resources(:proposals, "copied_from_component")
      expect(linked_proposals.count).to eq(2)
      expect(linked_proposals).to include(proposal, another_proposal)
    end

    context "with multiple authors" do
      let(:third_author) { create(:user, :confirmed, organization:) }
      let(:authors) { [author, another_author] }
      let(:other_authors) { [third_author, organization] }

      it "merges two proposals into one with all the authors" do
        visit current_path
        merge_proposals([proposal, another_proposal])
        expect(page).to have_css(".flash.success")
        expect(Decidim::Proposals::Proposal.where(deleted_at: nil).count).to eq(1)
        expect(Decidim::Proposals::Proposal.last.authors).to include(author, another_author, third_author, organization)
        expect(page).to have_css(".action-icon.action-icon--edit-proposal", count: 1)
      end
    end

    context "when proposals has comments" do
      let!(:comment) { create(:comment, commentable: proposal) }
      let!(:second_comment) { create(:comment, commentable: proposal) }
      let!(:third_comment) { create(:comment, commentable: another_proposal) }

      it "moves comments to merge proposal" do
        visit current_path
        merge_proposals([proposal, another_proposal])
        merge_proposal = Decidim::Proposals::Proposal.last
        expect(merge_proposal.comments.count).to eq(3)
        expect(merge_proposal.comments).to include(comment, second_comment, third_comment)
      end
    end

    context "when proposals have machine translations" do
      let(:proposal) { create(:proposal, body: first_body, component:, users: authors) }
      let(:another_proposal) { create(:proposal, body: second_body, component:, users: other_authors) }
      let(:first_body) do
        {
          "en" => "Hello world",
          "machine_translations" => first_machine_translations
        }
      end
      let(:second_body) do
        {
          "en" => "This is a test sentence",
          "machine_translations" => second_machine_translations
        }
      end
      let(:first_machine_translations) do
        {
          "fi" => "Hei maailma",
          "sv" => "Hej världen"
        }
      end
      let(:second_machine_translations) do
        {
          "fi" => "Tämä on testilause",
          "sv" => "Det här är en testmening"
        }
      end

      it "merges machine translations also" do
        expect(proposal.id).to be < another_proposal.id
        visit current_path
        merge_proposals([proposal, another_proposal])
        merge_proposal = Decidim::Proposals::Proposal.last
        expect(merge_proposal.body).to eq(
          {
            "en" => "Hello world\n\nThis is a test sentence",
            "machine_translations" => {
              "fi" => "Hei maailma\n\nTämä on testilause",
              "sv" => "Hej världen\n\nDet här är en testmening"
            }
          }
        )
      end
    end
  end

  def merge_proposals(proposals)
    Array(proposals).each do |proposal|
      find(".js-proposal-id-#{proposal.id}").set(true)
    end
    find_by_id("js-bulk-actions-button").click
    click_link_or_button "Merge into a new one"
    select translated(component.name), from: "target_component_id_"
    click_link_or_button "Merge"
  end
end
