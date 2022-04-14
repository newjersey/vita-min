require "rails_helper"

describe SubmissionBuilder::Ty2021::Documents::Schedule8812 do
  let(:filing_status) { "married_filing_jointly" }
  let(:submission) { create :efile_submission, :ctc, filing_status: filing_status, tax_year: 2021 }
  let!(:dependent) { create :qualifying_child, first_name: "Janis", intake: submission.intake }

  before do
    submission.intake.update(advance_ctc_amount_received: 900)
    submission.transition_to(:preparing)
    submission.reload
  end

  it "conforms to the eFileAttachments schema 2021v5.2" do
    instance = described_class.new(submission)
    expect(instance.schema_version).to eq "2021v5.2"

    expect(described_class.build(submission)).to be_valid
  end
end