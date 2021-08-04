require 'rails_helper'

describe Ctc::ConfirmLegalForm do
  let(:client) { create :client, tax_returns: [(create :tax_return, filing_status: nil)] }
  let!(:intake) { create :ctc_intake, client: client }
  let(:params) do
    {
      consented_to_legal: "yes",
      device_id: "7BA1E530D6503F380F1496A47BEB6F33E40403D1",
      user_agent: "GeckoFox",
      browser_language: "en-US",
      platform: "iPad",
      timezone_offset: "240",
      client_system_time: "Mon Aug 02 2021 18:55:41 GMT-0400 (Eastern Daylight Time)",
      ip_address: "1.1.1.1",
    }
  end

  context "validations" do
    context "when consented to legal is selected" do
      it "is valid" do
        expect(
          described_class.new(intake, params)
        ).to be_valid
      end
    end

    context "when consented to legal is not selected" do
      before do
        params[:consented_to_legal] = "no"
      end

      it "is not valid" do
        form = described_class.new(intake, params)
        expect(form).not_to be_valid
        expect(form.errors.keys).to include(:consented_to_legal)
      end
    end
  end

  context "save" do
    it "persists the consented to legal to intake and create an efile submission and set status to preparing" do
      expect { described_class.new(intake, params).save }
        .to change(intake.reload, :consented_to_legal).from("unfilled").to("yes")
                                                      .and change(intake.tax_returns.last.efile_submissions, :count).by(1)
    end

    it "persists efile_security_information as a record linked to the efile submission" do
      expect { described_class.new(intake, params).save }.to change(Client::EfileSecurityInformation, :count).by(1)
      efile_security_information = intake.tax_returns.last.efile_submissions.last.efile_security_information
      expect(efile_security_information.ip_address).to eq "1.1.1.1"
      expect(efile_security_information.device_id).to eq "7BA1E530D6503F380F1496A47BEB6F33E40403D1"
      expect(efile_security_information.user_agent).to eq "GeckoFox"
      expect(efile_security_information.browser_language).to eq "en-US"
      expect(efile_security_information.platform).to eq "iPad"
      expect(efile_security_information.timezone_offset).to eq "+240"
      expect(efile_security_information.client_system_time).to eq "Mon Aug 02 2021 18:55:41 GMT-0400 (Eastern Daylight Time)"
    end

    context 'when a submission already exists' do
      before do
        create :efile_submission, tax_return: intake.tax_returns.last
      end

      it "does not create another one" do
        expect { described_class.new(intake, params).save }
          .not_to change(intake.tax_returns.last.efile_submissions, :count)
      end
    end
  end
end
