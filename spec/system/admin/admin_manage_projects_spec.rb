# frozen_string_literal: true

require "spec_helper"

describe "Admin manages proposals", type: :system do
  let(:manifest_name) { "budgets" }
  let(:organization) { create(:organization) }
  let(:decidim_budgets) { Decidim::EngineRouter.admin_proxy(component) }

  let(:root_scope) { create(:scope, organization: organization) }
  let(:subscope1) { create(:scope, organization: organization, parent: root_scope) }
  let(:sub_subscope1) { create(:scope, organization: organization, parent: subscope1) }
  let(:sub_subscope2) { create(:scope, organization: organization, parent: subscope1) }

  let(:component_settings_base) { { scopes_enabled: true, scope_id: root_scope.id } }
  let!(:component) { create(:budgets_component, organization: organization) }
  let!(:budget) { create(:budget, component: component, scope: subscope1, title: { "en" => "budgets" }) }

  let!(:user) { create :user, :admin, :confirmed, organization: organization }

  before do
    component.update(settings: component_settings_base)
    switch_to_host(organization.host)
    sign_in user
  end

  context "when creating new project" do
    before do
      visit decidim_budgets.new_budget_project_path(budget)
    end

    it "lets select the parent scope" do
      expect(page).to have_select("project[decidim_scope_id]", options: ["Select a scope", subscope1.name["en"]])
    end
  end

  context "when editing project" do
    let!(:project) { create(:project, component: component, budget: budget, scope: sub_subscope1) }

    before do
      visit decidim_budgets.edit_budget_project_path(budget_id: budget.id, id: project.id)
    end

    it "lets select the parent scope" do
      expect(page).to have_select("project[decidim_scope_id]", options: ["Select a scope", sub_subscope1.name["en"]])
    end
  end

  context "when importing proposals" do
    let!(:proposal_component) { create(:proposal_component, participatory_space: component.participatory_space) }
    let!(:proposals) { create_list(:proposal, 3, component: proposal_component) }

    before do
      visit decidim_budgets.new_budget_proposals_import_path(budget)
    end

    it "shows the budget scope in options" do
      expect(page).to have_select("proposals_import[scope_id]", options: ["Select a scope", subscope1.name["en"]])
    end
  end
end
