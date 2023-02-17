require "rails_helper"

RSpec.describe Diy::ContinueToFsaController do
  describe "#edit" do
    let(:diy_intake_id) { create(:diy_intake, :filled_out).id }

    before do
      session[:diy_intake_id] = diy_intake_id
    end

    context "with a diy intake id in the session" do
      it "returns 200 OK" do
        get :edit

        expect(response).to be_ok
      end
    end

    context "without a valid diy intake id in the session" do
      let(:diy_intake_id) { nil }

      it "redirects to file yourself page" do
        get :edit

        expect(response).to redirect_to diy_file_yourself_path
      end
    end

    context "showing specific a TaxSlayer link" do
      it "shows the right TS link" do
        get :edit

        expect(assigns(:taxslayer_link)).to eq "https://www.taxslayer.com/v.aspx?rdr=/vitafsa&source=TSUSATY2022&sidn=01011934"
      end
    end
  end
end
