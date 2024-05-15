# frozen_string_literal: true

require "spec_helper"

describe "Admin manages component settings" do
  let(:manifest_name) { "proposals" }
  let(:organization) { create(:organization) }
  let(:scope) { create(:scope, organization:) }

  include_context "when managing a component as an admin"

  context "when component has scope" do
    before do
      component.update!(settings: { scopes_enabled: true, scope_id: scope.id })
    end

    describe "component settings" do
      before do
        click_on "Components"
        find(".action-icon.action-icon--configure").click
      end

      it "has scope preselected" do
        expect(page).to have_field("component[settings][scopes_enabled]", checked: true)
        expect(page).to have_select("component[settings][scope_id]", selected: scope.name["en"])
      end

      context "when there's antoher scope" do
        let!(:second_scope) { create(:scope, organization:) }

        before do
          visit current_path
        end

        it "can change scope" do
          select second_scope.name["en"], from: "component[settings][scope_id]"
          click_link_or_button "Update"
          expect(page).to have_content("The component was updated successfully")
          expect(Decidim::Component.find(component.id).scope.id).to eq(second_scope.id)
        end
      end
    end
  end
end
