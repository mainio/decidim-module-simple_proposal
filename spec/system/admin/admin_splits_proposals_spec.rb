# frozen_string_literal: true

require "spec_helper"

describe "Admin splits proposals" do
  let(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }
  let(:author) { create(:user, :confirmed, organization:) }
  let(:another_author) { create(:user, :confirmed, organization:) }
  let(:authors) { [author, another_author] }
  let(:proposal) { create(:proposal, component:, users: authors) }

  include_context "when managing a component as an admin"

  context "when there is proposal" do
    before do
      proposal
    end

    describe "split proposal" do
      it "duplicates proposal" do
        visit current_path
        split_proposals(proposal.id)
        expect(page).to have_css(".flash.success")
        expect(page).to have_css("tr[data-id='#{proposal.id}']")
        expect(page).to have_css("tr[data-id='#{proposal.id + 1}']")
        expect(page).to have_content(translated(proposal.title), count: 2)
        expect(Decidim::Proposals::Proposal.find(proposal.id + 1).authors).to include(author)
        expect(Decidim::Proposals::Proposal.find(proposal.id + 1).authors).to include(another_author)
        expect(Decidim::Proposals::Proposal.find(proposal.id + 1).authors).to include(organization)
        expect(page).to have_css(".action-icon.action-icon--edit-proposal", count: 2)
      end
    end

    it "links new proposal to original proposal" do
      visit current_path
      split_proposals(proposal.id)
      expect(page).to have_css(".flash.success")
      linked_proposals = Decidim::Proposals::Proposal.last.linked_resources(:proposals, "copied_from_component")
      expect(linked_proposals.count).to eq(1)
      expect(linked_proposals).to include(proposal)
    end

    describe "split multiple proposals" do
      let!(:another_proposal) { create(:proposal, component:, users: [author3]) }
      let(:author3) { create(:user, :confirmed, organization:) }

      it "duplicates each proposal" do
        visit current_path
        split_proposals([proposal.id, another_proposal.id])
        expect(page).to have_css(".flash.success")
        expect(page).to have_content(translated(proposal.title), count: 2)
        expect(page).to have_content(translated(another_proposal.title), count: 2)
        new_proposals = Decidim::Proposals::Proposal.last(2)
        new_proposal1 = new_proposals.select { |p| p.title == proposal.title }.first
        new_proposal2 = new_proposals.select { |p| p.title == another_proposal.title }.first
        expect(new_proposal1.authors).to eq(authors + [organization])
        expect(new_proposal2.authors).to eq([author3, organization])
        expect(page).to have_css(".action-icon.action-icon--edit-proposal", count: 4)
      end
    end

    context "when proposal has votes" do
      # :with_votes creates 5 votes by default
      let(:proposal) { create(:proposal, :with_votes, component:, users: authors) }

      it "does not copy votes" do
        visit current_path
        split_proposals(proposal.id)
        expect(page).to have_css(".flash.success")
        expect(page).to have_content(translated(proposal.title), count: 2)
        expect(Decidim::Proposals::Proposal.count).to eq(2)
        expect(Decidim::Proposals::Proposal.find(proposal.id).votes.count).to eq(5)
        expect(Decidim::Proposals::Proposal.last.votes.count).to eq(0)
        expect(page).to have_css(".action-icon.action-icon--edit-proposal", count: 2)
      end
    end
  end

  def split_proposals(proposal_ids)
    Array(proposal_ids).each do |id|
      find(".js-proposal-id-#{id}").set(true)
    end
    find_by_id("js-bulk-actions-button").click
    click_link_or_button "Split proposals"
    select translated(component.name), from: "target_component_id_"
    click_link_or_button "Split"
  end
end
