# frozen_string_literal: true

require "spec_helper"

describe "Admin splits proposals", type: :system do
  let(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }

  let(:author) { create(:user, :confirmed, organization: organization) }
  let(:another_author) { create(:user, :confirmed, organization: organization) }

  let(:proposal) { create(:proposal, component: component, users: authors) }
  let(:authors) { [author] }

  let(:another_proposal) { create(:proposal, component: component, users: other_authors) }
  let(:other_authors) { [another_author] }

  include_context "when managing a component as an admin"

  describe "merge proposals" do
    before do
      proposal
      another_proposal
    end

    it "merges proposals" do
      visit current_path
      merge_proposals([proposal.id, another_proposal.id])
      expect(page).to have_css(".callout.success")
      expect(page).to have_content(translated(another_proposal.title))
      expect(Decidim::Proposals::Proposal.count).to eq(1)
      expect(Decidim::Proposals::Proposal.last.body).to eq(another_proposal.body)
      expect(Decidim::Proposals::Proposal.last.authors.count).to eq(3)
      expect(Decidim::Proposals::Proposal.last.authors).to include(author)
      expect(Decidim::Proposals::Proposal.last.authors).to include(another_author)
      expect(Decidim::Proposals::Proposal.last.authors).to include(organization)
      expect(page).to have_selector(".icon.icon--pencil", count: 1)
    end

    context "with multiple authors" do
      let(:author3) { create(:user, :confirmed, organization: organization) }
      let(:authors) { [author, another_author] }
      let(:other_authors) { [author3, organization] }

      it "merges two proposals into one with all the authors" do
        visit current_path
        merge_proposals([proposal.id, another_proposal.id])
        expect(page).to have_css(".callout.success")
        expect(Decidim::Proposals::Proposal.count).to eq(1)
        expect(Decidim::Proposals::Proposal.last.authors).to include(author, another_author, author3, organization)
        expect(page).to have_selector(".icon.icon--pencil", count: 1)
      end
    end
  end

  def merge_proposals(proposal_ids)
    Array(proposal_ids).each do |id|
      find(".js-proposal-id-#{id}").set(true)
    end
    find("#js-bulk-actions-button").click
    click_button "Merge into a new one"
    select translated(component.name), from: "target_component_id_"
    click_button "Merge"
  end
end
