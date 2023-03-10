class PersonalInfoForm < QuestionsForm
  include DateHelper

  set_attributes_for(
    :intake,
    :preferred_name,
    :phone_number,
    :birth_date_year,
    :birth_date_month,
    :birth_date_day,
    :zip_code,
    :timezone,
    :source,
    :referrer,
    :locale,
    :visitor_id,
  )

  set_attributes_for(
    :confirmation,
    :phone_number_confirmation,
  )

  before_validation :normalize_phone_numbers

  validates :zip_code, zip_code: true
  validates :preferred_name, presence: true
  validates :phone_number, presence: true, confirmation: true, e164_phone: true
  validates :phone_number_confirmation, presence: true
  validate :valid_birth_date

  def normalize_phone_numbers
    self.phone_number = PhoneParser.normalize(phone_number) if phone_number.present?
    self.phone_number_confirmation = PhoneParser.normalize(phone_number_confirmation) if phone_number_confirmation.present?
  end

  def save
    state = ZipCodes.details(zip_code)[:state]
    client = Client.create!(
      intake_attributes: attributes_for(:intake)
                           .except(:birth_date_year, :birth_date_month, :birth_date_day)
                           .merge(
                             type: @intake.type,
                             state_of_residence: state,
                             product_year: Rails.configuration.product_year,
                             primary_birth_date: parse_date_params(birth_date_year, birth_date_month, birth_date_day)
                           )
    )
    @intake = client.intake

    data = MixpanelService.data_from([@intake.client, @intake])
    MixpanelService.send_event(
      distinct_id: @intake.visitor_id,
      event_name: "intake_started",
      data: data
    )
  end

  def self.existing_attributes(intake)
    attributes = HashWithIndifferentAccess.new(intake.attributes)
    if attributes[:primary_birth_date].present?
      birth_date = attributes[:primary_birth_date]
      attributes.merge!(
        birth_date_year: birth_date.year,
        birth_date_month: birth_date.month,
        birth_date_day: birth_date.day,
      )
    end
    attributes
  end
end