# frozen_string_literal: true

require "spec_helper"

describe "Admin manages component settings", type: :system do
  let(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }
  let(:scope) { create(:scope, organization: organization) }

  include_context "when managing a component as an admin"

  context "when component has scope" do
    before do
      component.update!(settings: { scopes_enabled: true, scope_id: scope.id })
    end

    describe "component settings" do
      before do
        click_link "Components"
        find(".icon--cog").click
      end

      it "has scope preselected" do
        expect(page).to have_field("component[settings][scopes_enabled]", checked: true)
        expect(page).to have_select("component[settings][scope_id]", selected: scope.name["en"])
      end

      context "when there's antoher scope" do
        let!(:scope2) { create(:scope, organization: organization) }

        before do
          visit current_path
        end

        it "can change scope" do
          select scope2.name["en"], from: "component[settings][scope_id]"
          click_button "Update"
          expect(page).to have_content("The component was updated successfully")
          expect(Decidim::Component.find(component.id).scope.id).to eq(scope2.id)
        end
      end
    end
  end
end
