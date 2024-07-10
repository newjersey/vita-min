# == Schema Information
#
# Table name: state_file_nj_intakes
#
#  id                                :bigint           not null, primary key
#  account_type                      :integer          default("unfilled"), not null
#  claimed_as_dep                    :integer
#  consented_to_terms_and_conditions :integer          default("unfilled"), not null
#  contact_preference                :integer          default("unfilled"), not null
#  current_sign_in_at                :datetime
#  current_sign_in_ip                :inet
#  current_step                      :string
#  eligibility_lived_in_state        :integer          default("unfilled"), not null
#  eligibility_out_of_state_income   :integer          default("unfilled"), not null
#  email_address                     :citext
#  email_address_verified_at         :datetime
#  failed_attempts                   :integer          default(0), not null
#  fed_taxable_income                :integer
#  fed_wages                         :integer
#  filing_status                     :integer
#  last_sign_in_at                   :datetime
#  last_sign_in_ip                   :inet
#  locale                            :string           default("en")
#  locked_at                         :datetime
#  payment_or_deposit_type           :integer          default("unfilled"), not null
#  permanent_apartment               :string
#  permanent_city                    :string
#  permanent_street                  :string
#  permanent_zip                     :string
#  phone_number                      :string
#  phone_number_verified_at          :datetime
#  primary_dob                       :date
#  primary_esigned                   :integer          default("unfilled"), not null
#  primary_first_name                :string
#  primary_last_name                 :string
#  primary_middle_initial            :string
#  primary_ssn                       :string
#  raw_direct_file_data              :text
#  referrer                          :string
#  sign_in_count                     :integer          default(0), not null
#  source                            :string
#  spouse_dob                        :date
#  spouse_esigned                    :integer          default("unfilled"), not null
#  spouse_first_name                 :string
#  spouse_last_name                  :string
#  spouse_middle_initial             :string
#  spouse_ssn                        :string
#  tax_return_year                   :integer
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  visitor_id                        :string
#
FactoryBot.define do
  factory :state_file_nj_intake do
    
  end
end
