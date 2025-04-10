# frozen_string_literal: true

require "spec_helper"

describe Decidim::ScopesHelper do
  let(:organization) { create(:organization) }

  describe "#scopes_picker_field" do
    subject do
      Nokogiri::HTML(helper.scopes_picker_field(form, :decidim_scope_id, root: root))
    end

    let(:target) { subject.css("select") }

    let(:root_scope) { create(:scope, organization: organization) }
    let(:scopes) { create_list(:scope, 4, parent: root_scope) }
    let(:another_root_scope) { create(:scope, organization: organization) }
    let!(:other_scopes) { create_list(:scope, 2, parent: another_root_scope) }
    let(:object) do
      instance_double(
        Decidim::Budgets::Admin::BudgetForm,
        decidim_scope_id: selected_scope&.id
      )
    end
    let(:root) { false }
    let(:selected_scope) { scopes[0] }

    let(:form) { Decidim::FormBuilder.new(:budget, object, template, {}) }
    let(:template) { Class.new(ActionView::Base).new(ActionView::LookupContext.new(ActionController::Base.view_paths), {}, []) }

    shared_examples "selected scope" do
      let(:level) do
        level = 0
        current = selected_scope
        if current != root
          root_id = root ? root.id : nil
          while current.parent_id != root_id
            level += 1
            current = current.parent
          end
        end
        level
      end

      it "sets the selected value correctly" do
        selected = target.css("option[selected]").first
        expect(selected["value"]).to eq(selected_scope.id.to_s)
        expect(selected.text).to eq("#{level > 0 ? "#{"-" * level} " : ""}#{translated(selected_scope.name)}")
      end
    end

    it "renders the scope picker correctly" do
      expect(target).to have_css("option", text: translated(root_scope.name))
      scopes.each do |scope|
        expect(target).to have_css("option", text: "- #{translated(scope.name)}")
      end
      expect(target).to have_css("option", text: translated(another_root_scope.name))
      other_scopes.each do |scope|
        expect(target).to have_css("option", text: "- #{translated(scope.name)}")
      end
    end

    it_behaves_like "selected scope"

    # it "sets the selected value correctly" do
    #   selected = target.css("option[selected]").first
    #   expect(selected["value"]).to eq(selected_scope.id.to_s)
    #   expect(selected.text).to eq("- #{translated(selected_scope.name)}")
    # end

    context "with root scope" do
      let(:root) { root_scope }

      it "renders only the scopes under the root scope" do
        expect(target).not_to have_css("option", text: translated(root_scope.name))
        scopes.each do |scope|
          expect(target).to have_css("option", text: translated(scope.name))
        end
        expect(target).not_to have_css("option", text: translated(another_root_scope.name))
        other_scopes.each do |scope|
          expect(target).not_to have_css("option", text: translated(scope.name))
        end
      end

      # it "sets the selected value correctly" do
      #   selected = target.css("option[selected]").first
      #   expect(selected["value"]).to eq(selected_scope.id.to_s)
      #   expect(selected.text).to eq(translated(selected_scope.name))
      # end

      it_behaves_like "selected scope"

      context "without children" do
        let(:scopes) { [] }
        let(:selected_scope) { root_scope }

        it "renders only the root scope" do
          expect(target.css("option").length).to eq(2)
          expect(target.css("option")[0]["value"]).to eq("")
          expect(target.css("option")[0].text).to eq("Select a scope")
          expect(target.css("option")[1]["value"]).to eq(root_scope.id.to_s)
          expect(target.css("option")[1].text).to eq(translated(root_scope.name))
        end

        # it "sets the selected value correctly" do
        #   selected = target.css("option[selected]").first
        #   expect(selected["value"]).to eq(selected_scope.id.to_s)
        #   expect(selected.text).to eq(translated(selected_scope.name))
        # end

        it_behaves_like "selected scope"
      end
    end
  end
end
