# == Schema Information
#
# Table name: state_file_ny_intakes
#
#  id                             :bigint           not null, primary key
#  account_number                 :string
#  account_type                   :integer          default("unfilled"), not null
#  amount_electronic_withdrawal   :integer
#  amount_owed_pay_electronically :integer          default("unfilled"), not null
#  claimed_as_dep                 :integer          not null
#  current_step                   :string
#  date_electronic_withdrawal     :date
#  fed_taxable_income             :integer
#  fed_taxable_ssb                :integer
#  fed_unemployment               :integer
#  fed_wages                      :integer
#  filing_status                  :integer          not null
#  household_cash_assistance      :integer
#  household_fed_agi              :integer
#  household_ny_additions         :integer
#  household_other_income         :integer
#  household_own_assessments      :integer
#  household_own_propety_tax      :integer
#  household_rent_adjustments     :integer
#  household_rent_amount          :integer
#  household_rent_own             :integer          default("unfilled"), not null
#  household_ssi                  :integer
#  mailing_apartment              :string
#  mailing_city                   :string
#  mailing_country                :string
#  mailing_state                  :string
#  mailing_street                 :string
#  mailing_zip                    :string
#  nursing_home                   :integer          default("unfilled"), not null
#  ny_414h_retirement             :integer
#  ny_mailing_apartment           :string
#  ny_mailing_city                :string
#  ny_mailing_street              :string
#  ny_mailing_zip                 :string
#  ny_other_additions             :integer
#  nyc_resident_e                 :integer          default("unfilled"), not null
#  occupied_residence             :integer          default("unfilled"), not null
#  permanent_apartment            :string
#  permanent_city                 :string
#  permanent_street               :string
#  permanent_zip                  :string
#  phone_daytime                  :string
#  phone_daytime_area_code        :string
#  primary_dob                    :date
#  primary_email                  :string
#  primary_first_name             :string
#  primary_last_name              :string
#  primary_middle_initial         :string
#  primary_occupation             :string
#  primary_signature              :string
#  primary_ssn                    :string
#  property_over_limit            :integer          default("unfilled"), not null
#  public_housing                 :integer          default("unfilled"), not null
#  refund_choice                  :integer          default("unfilled"), not null
#  residence_county               :string
#  routing_number                 :string
#  sales_use_tax                  :integer
#  school_district                :string
#  school_district_number         :integer
#  spouse_dob                     :date
#  spouse_first_name              :string
#  spouse_last_name               :string
#  spouse_middle_initial          :string
#  spouse_occupation              :string
#  spouse_signature               :string
#  spouse_ssn                     :string
#  tax_return_year                :integer
#  total_fed_adjustments          :integer
#  total_fed_adjustments_identify :string
#  total_state_tax_withheld       :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  visitor_id                     :string
#
class StateFileNyIntake < StateFileBaseIntake
  enum nyc_resident_e: { unfilled: 0, yes: 1, no: 2 }, _prefix: :nyc_resident_e
  enum refund_choice: { unfilled: 0, paper: 1, direct_deposit: 2 }, _prefix: :refund_choice
  enum account_type: { unfilled: 0, personal_checking: 1, personal_savings: 2, business_checking: 3, business_savings: 4 }, _prefix: :account_type
  enum amount_owed_pay_electronically: { unfilled: 0, yes: 1, no: 2 }, _prefix: :amount_owed_pay_electronically
  enum occupied_residence: { unfilled: 0, yes: 1, no: 2 }, _prefix: :occupied_residence
  enum property_over_limit: { unfilled: 0, yes: 1, no: 2 }, _prefix: :property_over_limit
  enum public_housing: { unfilled: 0, yes: 1, no: 2 }, _prefix: :public_housing
  enum nursing_home: { unfilled: 0, yes: 1, no: 2 }, _prefix: :nursing_home
  enum household_rent_own: { unfilled: 0, rent: 1, own: 2 }, _prefix: :household_rent_own

  def tax_calculator
    field_by_line_id = {
      AMT_1: :fed_wages,
      AMT_2: :fed_taxable_income,
      AMT_14: :fed_unemployment,
      AMT_15: :fed_taxable_ssb,
      AMT_18: :total_fed_adjustments,
      AMT_21: 0, # TODO: this will be a certain subset of the w2 income
      AMT_23: :ny_other_additions,
      AMT_27: :fed_taxable_ssb,
      AMT_59: :sales_use_tax,
      AMT_72: :total_state_tax_withheld,
      # AMT_73: :total_city_tax_withheld, TODO
    }
    input_lines = {}
    field_by_line_id.each do |line_id, field|
      input_lines[line_id] =
        if field.is_a?(Symbol)
          Efile::TaxFormLine.from_data_source(line_id, self, field)
        else
          Efile::TaxFormLine.new(line_id, field, "Static", [])
        end
    end
    Efile::Ny::It201.new(
      year: 2022,
      filing_status: filing_status.to_sym,
      claimed_as_dependent: claimed_as_dep_yes?,
      dependent_count: dependents.length,
      input_lines: input_lines,
      it213: Efile::Ny::It213.new,
      it214: Efile::Ny::It214.new,
      it215: Efile::Ny::It215.new,
      it227: Efile::Ny::It227.new
    )
  end
end
