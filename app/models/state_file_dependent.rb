# == Schema Information
#
# Table name: state_file_dependents
#
#  id             :bigint           not null, primary key
#  dob            :date
#  first_name     :string
#  intake_type    :string           not null
#  last_name      :string
#  middle_initial :string
#  relationship   :string
#  ssn            :string
#  suffix         :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  intake_id      :bigint           not null
#
# Indexes
#
#  index_state_file_dependents_on_intake  (intake_type,intake_id)
#
class StateFileDependent < ApplicationRecord
  belongs_to :intake, polymorphic: true

  # Create birth_date_* accessor methods for Honeycrisp's cfa_date_select
  delegate :month, :day, :year, to: :dob, prefix: :dob, allow_nil: true

  def full_name
    parts = [first_name, middle_initial, last_name]
    parts << suffix if suffix.present?
    parts.compact.join(' ')
  end
end