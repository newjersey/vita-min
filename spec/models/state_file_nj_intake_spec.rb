# == Schema Information
#
# Table name: state_file_nj_intakes
#
#  id                                :bigint           not null, primary key
#  account_number                    :string
#  account_type                      :integer          default("unfilled"), not null
#  bank_name                         :string
#  claimed_as_dep                    :integer
#  consented_to_terms_and_conditions :integer          default("unfilled"), not null
#  contact_preference                :integer          default("unfilled"), not null
#  current_sign_in_at                :datetime
#  current_sign_in_ip                :inet
#  current_step                      :string
#  date_electronic_withdrawal        :date
#  df_data_import_failed_at          :datetime
#  df_data_imported_at               :datetime
#  eligibility_lived_in_state        :integer          default("unfilled"), not null
#  eligibility_out_of_state_income   :integer          default("unfilled"), not null
#  email_address                     :citext
#  email_address_verified_at         :datetime
#  failed_attempts                   :integer          default(0), not null
#  fed_taxable_income                :integer
#  fed_wages                         :integer
#  federal_return_status             :string
#  filing_status                     :integer
#  hashed_ssn                        :string
#  last_sign_in_at                   :datetime
#  last_sign_in_ip                   :inet
#  locale                            :string           default("en")
#  locked_at                         :datetime
#  message_tracker                   :jsonb
#  payment_or_deposit_type           :integer          default("unfilled"), not null
#  permanent_apartment               :string
#  permanent_city                    :string
#  permanent_street                  :string
#  permanent_zip                     :string
#  phone_number                      :string
#  phone_number_verified_at          :datetime
#  primary_birth_date                :date
#  primary_esigned                   :integer          default("unfilled"), not null
#  primary_esigned_at                :datetime
#  primary_first_name                :string
#  primary_last_name                 :string
#  primary_middle_initial            :string
#  primary_signature                 :string
#  primary_ssn                       :string
#  primary_suffix                    :string
#  raw_direct_file_data              :text
#  referrer                          :string
#  routing_number                    :string
#  sign_in_count                     :integer          default(0), not null
#  source                            :string
#  spouse_birth_date                 :date
#  spouse_esigned                    :integer          default("unfilled"), not null
#  spouse_esigned_at                 :datetime
#  spouse_first_name                 :string
#  spouse_last_name                  :string
#  spouse_middle_initial             :string
#  spouse_ssn                        :string
#  spouse_suffix                     :string
#  tax_return_year                   :integer
#  unfinished_intake_ids             :text             default([]), is an Array
#  unsubscribed_from_email           :boolean          default(FALSE), not null
#  withdraw_amount                   :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  federal_submission_id             :string
#  primary_state_id_id               :bigint
#  spouse_state_id_id                :bigint
#  visitor_id                        :string
#
# Indexes
#
#  index_state_file_nj_intakes_on_email_address        (email_address)
#  index_state_file_nj_intakes_on_hashed_ssn           (hashed_ssn)
#  index_state_file_nj_intakes_on_primary_state_id_id  (primary_state_id_id)
#  index_state_file_nj_intakes_on_spouse_state_id_id   (spouse_state_id_id)
#
require 'rails_helper'

RSpec.describe StateFileNjIntake, type: :model do
  describe "#disqualifying_eligibility_answer" do
    it "returns nil when they haven't answered any questions yet" do
      intake = build(:state_file_nj_intake)
      expect(intake.disqualifying_eligibility_answer).to be_nil
    end

    it "returns :eligibility_lived_in_state when they haven't been a resident the whole year" do
      intake = build(:state_file_nj_intake, eligibility_lived_in_state: "no")
      expect(intake.disqualifying_eligibility_answer).to eq :eligibility_lived_in_state
    end

    it "returns :eligibility_out_of_state_income when they earned income in another state" do
      intake = build(:state_file_nj_intake, eligibility_out_of_state_income: "yes")
      expect(intake.disqualifying_eligibility_answer).to eq :eligibility_out_of_state_income
    end
  end

  describe "#has_disqualifying_eligibility_answer?" do
    it "returns false when they haven't answered any questions yet" do
      intake = build(:state_file_nj_intake)
      expect(intake.has_disqualifying_eligibility_answer?).to eq false
    end

    it "returns true when they haven't been a resident the whole year" do
      intake = build(:state_file_nj_intake, eligibility_lived_in_state: "no")
      expect(intake.has_disqualifying_eligibility_answer?).to eq true
    end

    it "returns true when they earned income in another state" do
      intake = build(:state_file_nj_intake, eligibility_out_of_state_income: "yes")
      expect(intake.has_disqualifying_eligibility_answer?).to eq true
    end
  end

  describe "#disqualifying_df_data_reason" do
    let(:intake) { create :state_file_nj_intake }

    it "returns nil when direct file data has no disqualifying fields" do
      expect(intake.disqualifying_df_data_reason).to be_nil
    end

    # TODO: is this a case we will support or not?
    it "returns has_out_of_state_w2 when direct file data has an out of state W2" do
      w2 = intake.direct_file_data.w2_nodes.first
      state_abbreviation_cd = w2.at("W2StateLocalTaxGrp W2StateTaxGrp StateAbbreviationCd")
      state_abbreviation_cd.inner_html = "UT"

      expect(intake.disqualifying_df_data_reason).to eq :has_out_of_state_w2
    end
  end


  describe "invalid_df_w2?" do
    let(:intake) { create :state_file_nj_intake }

    it 'accepts any combination of alpphnumeric characters and spaces' do
      df_w2 = intake.direct_file_data.w2s[0]
      df_w2.LocalityNm = "ALPHANUMERIC CHARACTERS"
      expect(intake.invalid_df_w2?(df_w2)).to eq false
    end

    it 'validates that W2s do not show more tax paid than money earned' do
      df_w2 = intake.direct_file_data.w2s[0]
      df_w2.StateIncomeTaxAmt = df_w2.StateWagesAmt + 100
      expect(intake.invalid_df_w2?(df_w2)).to eq true
    end
  end


  describe "state_code" do
    describe ".state_code" do
      it "finds the right state code from the state information service" do
        expect(described_class.state_code).to eq "nj"
      end
    end

    describe "#state_code" do
      it "delegates to the instance method from the class method" do
        intake = create(:state_file_nj_intake)
        expect(intake.state_code).to eq "nj"
      end
    end
  end
end
