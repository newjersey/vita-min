require "rails_helper"

RSpec.describe Documents::SsnItinsController do
  let(:filing_joint) { "no" }
  let(:intake) do
    create(
      :intake,
      filing_joint: filing_joint,
      primary_first_name: "Gary",
      primary_last_name: "Gnome"
    )
  end

  before do
    Experiment.update_all(enabled: true)

    sign_in intake.client
  end

  describe "#edit" do
    it_behaves_like :a_required_document_controller

    context "when they do not have a spouse" do
      let(:filing_joint) { "no" }

      it "lists only their name" do
        get :edit

        expect(assigns(:names)).to eq ["Gary Gnome"]
      end
    end

    context "when they are filing jointly" do
      context "when we have the spouse name" do
        let(:filing_joint) { "yes" }
        before do
          intake.update(
            spouse_first_name: "Greta",
            spouse_last_name: "Gnome",
          )
        end

        it "includes their name in the list" do
          get :edit

          expect(assigns(:names)).to include "Greta Gnome"
        end
      end

      context "when we don't have the spouse name" do
        let(:filing_joint) { "yes" }

        it "includes placeholder in the list" do
          get :edit

          expect(assigns(:names)).to include "Your spouse"
        end
      end
    end

    context "when they have dependents" do
      before { create :dependent, first_name: "Gracie", last_name: "Gnome", intake: intake }

      it "includes their names in the list" do
        get :edit

        expect(assigns(:names)).to include "Gracie Gnome"
      end
    end
  end

  describe '#update' do
    context "when upload is valid" do
      let!(:tax_return) { create :gyr_tax_return, :intake_in_progress, client: intake.client }
      let(:params) do
        {
          document_type_upload_form: {
            upload: fixture_file_upload("test-pattern.JPG")
          }
        }
      end

      context 'all three required doc types are present' do
        before do
          create :document, document_type: DocumentTypes::Identity.key, intake: intake, client: intake.client
          create :document, document_type: DocumentTypes::Employment.key, intake: intake, client: intake.client
        end

        it "updates the tax return status(es) to intake_ready" do
          post :update, params: params

          expect(tax_return.reload.current_state).to eq "intake_ready"
        end
      end

      context 'required doc types are missing' do
        it "updates the tax return status(es) to intake_needs_doc_help" do
          post :update, params: params

          expect(tax_return.reload.current_state).to eq "intake_needs_doc_help"
        end

        context "the current state is already needs doc help" do
          it "does not create a new transition"do
            post :update, params: params

            expect(tax_return.reload.current_state).to eq "intake_needs_doc_help"

            expect {
              expect {
                post :update, params: {
                  document_type_upload_form: {
                    upload: fixture_file_upload("test-pattern.JPG")
                  }
                }
              }.to change(Document, :count).by(1)
            }.not_to change(tax_return.tax_return_transitions, :count)

            expect(tax_return.reload.current_state).to eq "intake_needs_doc_help"
          end
        end
      end
    end
  end


  describe "#delete" do
    let!(:document) { create :document, intake: intake }

    let(:params) do
      { id: document.id }
    end

    it "allows client to delete their own document and records a paper trail" do
      delete :destroy, params: params

      expect(PaperTrail::Version.last.event).to eq "destroy"
      expect(PaperTrail::Version.last.whodunnit).to eq intake.client.id.to_s
      expect(PaperTrail::Version.last.item_id).to eq document.id
    end
  end
end
