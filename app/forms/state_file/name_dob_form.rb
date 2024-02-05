module StateFile
  class NameDobForm < QuestionsForm
    include DateHelper

    attr_accessor :dependents_attributes

    set_attributes_for :intake,
                       :primary_first_name,
                       :primary_last_name,
                       :spouse_first_name,
                       :spouse_last_name,
                       :primary_birth_date_month, :primary_birth_date_day, :primary_birth_date_year,
                       :spouse_birth_date_month, :spouse_birth_date_day, :spouse_birth_date_year


    delegate :ask_months_in_home?,
             :ask_spouse_dob?,
             :ask_spouse_name?,
             :filing_status_mfj?,
             :hoh_qualifying_person_name,
             to: :intake

    validates_presence_of :primary_first_name, :primary_last_name
    validates_presence_of :spouse_first_name, :spouse_last_name, if: -> { @intake.ask_spouse_name? }
    validates_presence_of :hoh_qualifying_person_name, if: -> {  @intake.class == StateFileAzIntake && @intake.requires_hoh_qualifying_person_name? }
    validate :primary_birth_date_is_valid_date
    validate :spouse_birth_date_is_valid_date, if: -> { @intake.ask_spouse_dob? }

    def initialize(intake = nil, params = nil)
      super
      if params.present?
        @intake.assign_attributes(dependents_attributes: formatted_dependents_attributes)
      end
    end

    def dependents
      @intake.dependents
    end

    def save
      attributes_to_update = {
        primary_first_name: primary_first_name,
        primary_last_name: primary_last_name,
        dependents_attributes: formatted_dependents_attributes
      }
      if @intake.ask_spouse_name?
        attributes_to_update.merge!(
          spouse_first_name: spouse_first_name,
          spouse_last_name: spouse_last_name,
        )
      end
      attributes_to_update[:primary_birth_date] = primary_birth_date
      attributes_to_update[:spouse_birth_date] = spouse_birth_date if @intake.ask_spouse_dob?
      @intake.update!(attributes_to_update)
    end

    def valid?
      dependents_valid = dependents.map { |d| d.valid?(:dob_form) }

      super && dependents_valid.all?
    end

    def self.existing_attributes(intake)
      attributes = super
      attributes.merge!(
        primary_birth_date_day: intake.primary_birth_date&.day,
        primary_birth_date_month: intake.primary_birth_date&.month,
        primary_birth_date_year: intake.primary_birth_date&.year,
      )
      if intake.ask_spouse_dob?
        attributes.merge!(
          spouse_birth_date_day: intake.spouse_birth_date&.day,
          spouse_birth_date_month: intake.spouse_birth_date&.month,
          spouse_birth_date_year: intake.spouse_birth_date&.year,
        )
      end
      attributes
    end

    private

    def formatted_dependents_attributes
      dependents_attributes&.map { |k, v| [k, formatted_dependent_attrs(v)] }.to_h
    end

    def formatted_dependent_attrs(attrs)
      if attrs[:dob_day] && attrs[:dob_month] && attrs[:dob_year]
        attrs[:dob] = "#{attrs[:dob_year]}-#{attrs[:dob_month]}-#{attrs[:dob_day]}"
      end
      attrs.except!(:dob_month, :dob_day, :dob_year)
    end

    def primary_birth_date
      parse_date_params(primary_birth_date_year, primary_birth_date_month, primary_birth_date_day)
    end

    def spouse_birth_date
      parse_date_params(spouse_birth_date_year, spouse_birth_date_month, spouse_birth_date_day)
    end

    def primary_birth_date_is_valid_date
      valid_text_birth_date(primary_birth_date_year, primary_birth_date_month, primary_birth_date_day, :primary_birth_date)
    end

    def spouse_birth_date_is_valid_date
      valid_text_birth_date(spouse_birth_date_year, spouse_birth_date_month, spouse_birth_date_day, :spouse_birth_date)
    end
  end
end