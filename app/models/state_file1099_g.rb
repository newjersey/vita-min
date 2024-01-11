# == Schema Information
#
# Table name: state_file1099_gs
#
#  id                                 :bigint           not null, primary key
#  address_confirmation               :integer          default("unfilled"), not null
#  federal_income_tax_withheld        :integer
#  had_box_11                         :integer          default("unfilled"), not null
#  intake_type                        :string           not null
#  payer_city                         :string
#  payer_name                         :string
#  payer_street_address               :string
#  payer_tin                          :string
#  payer_zip                          :string
#  recipient                          :integer          default("unfilled"), not null
#  recipient_city                     :string
#  recipient_street_address           :string
#  recipient_street_address_apartment :string
#  recipient_zip                      :string
#  state_identification_number        :string
#  state_income_tax_withheld          :integer
#  unemployment_compensation          :integer
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  intake_id                          :bigint           not null
#
# Indexes
#
#  index_state_file1099_gs_on_intake  (intake_type,intake_id)
#
class StateFile1099G < ApplicationRecord
  belongs_to :intake, polymorphic: true
  before_validation :update_conditional_attributes

  enum address_confirmation: { unfilled: 0, yes: 1, no: 2 }, _prefix: :address_confirmation
  enum had_box_11: { unfilled: 0, yes: 1, no: 2 }, _prefix: :had_box_11
  enum recipient: { unfilled: 0, primary: 1, spouse: 2 }, _prefix: :recipient

  validates_inclusion_of :had_box_11, in: ['yes', 'no'], message: ->(_object, _data) { I18n.t("errors.messages.blank") }
  validates_presence_of :payer_name, :message => I18n.t("errors.attributes.payer_name.blank")
  validates_presence_of :payer_street_address, :message => I18n.t("errors.attributes.address.street_address.blank")
  validates_presence_of :payer_city, :message => I18n.t("errors.attributes.address.city.blank")
  validates_presence_of :payer_zip, :message => I18n.t("errors.attributes.address.zip.blank")
  validates :payer_tin, format: { :with => /\d{9}/, :message => I18n.t("errors.attributes.payer_tin.blank")}
  validates_presence_of :state_identification_number, :message => I18n.t("errors.attributes.state_id_number.empty")
  validates_presence_of :recipient_city
  validates_presence_of :recipient_street_address
  validates_presence_of :recipient_zip
  validates :unemployment_compensation, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :federal_income_tax_withheld, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :state_income_tax_withheld, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  def update_conditional_attributes
    if address_confirmation_yes?
      self.recipient_city = intake.direct_file_data.mailing_city
      self.recipient_street_address = intake.direct_file_data.mailing_street
      self.recipient_street_address_apartment = intake.direct_file_data.mailing_apartment
      self.recipient_zip = intake.direct_file_data.mailing_zip
    end
  end

  def recipient_name
    if recipient_primary?
      intake.primary.full_name
    elsif recipient_spouse?
      intake.spouse.full_name
    end
  end

  def recipient_address_line1
    "#{recipient_street_address_apartment} #{recipient_street_address}".strip
  end
end
