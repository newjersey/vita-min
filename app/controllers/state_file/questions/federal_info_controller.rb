module StateFile
  module Questions
    class FederalInfoController < QuestionsController
      layout "state_file/question"

      def import_federal_data
        if current_intake.persisted?
          flash[:alert] = "not overriding existing session intake for now"
          redirect_to action: :edit, us_state: params[:us_state]
        else
          create_sample_intake
          direct_file_xml = IrsApiService.import_federal_data('fake_auth_token')

          current_intake.update(raw_direct_file_data: direct_file_xml)
          redirect_to action: :edit, us_state: params[:us_state]
        end
      end

      private

      def current_intake
        super_value = super
        if super_value.present?
          super_value
        else
          question_navigator.intake_class.new
        end
      end

      def illustration_path
        "wages.svg"
      end

      def after_update_success
        session[:state_file_intake] = current_intake.to_global_id
      end

      def create_sample_intake
        case params[:us_state]
        when "ny"
          intake = StateFileNyIntake.create(
            primary_first_name: "Testy",
            primary_middle_initial: "T",
            primary_last_name: "Testerson",
            claimed_as_dep: "no",
            primary_email: "whatever@example.com",
            date_electronic_withdrawal: Date.today,
            residence_county: "County",
            school_district: "Pizza District",
            school_district_number: 234,
            permanent_street: "123 Main St",
            permanent_apartment: "3",
            permanent_city: "New York",
            permanent_zip: "10112",
            nyc_full_year_resident: "yes",
            ny_414h_retirement: 567,
            ny_other_additions: 123,
            sales_use_tax: 345,
            amount_owed_pay_electronically: "yes",
            refund_choice: "paper",
            account_type: "personal_checking",
            routing_number: "34567878",
            account_number: "456789008765",
            amount_electronic_withdrawal: 768,
            primary_signature: "beep boop",
            spouse_signature: "hup",
            **it214_fields
          )
          intake.dependents.create(
            first_name: "Adult",
            middle_initial: 'C',
            last_name: "Deppy",
            relationship: Efile::Relationship.find('grandparent').irs_enum,
            ssn: '555003333',
            dob: 60.years.ago
          )
          intake.dependents.create(
            first_name: "Child",
            middle_initial: 'E',
            last_name: "Deppy",
            relationship: Efile::Relationship.find('daughter').irs_enum,
            ssn: '555004444',
            dob: 6.years.ago
          )
        when "az"
          intake = StateFileAzIntake.create(
            claimed_as_dep: "no",
            primary_first_name: "Testy",
            primary_middle_initial: "T",
            primary_last_name: "Testerson",
          )
        else
          raise "No state specified"
        end
        session[:state_file_intake] = intake.to_global_id
      end

      def it214_fields
        {
          ny_mailing_street: "123 Homeowner way",
          ny_mailing_apartment: "B",
          ny_mailing_city: "Brooklyn",
          ny_mailing_zip: "10113",
          occupied_residence: "yes",
          property_over_limit: "no",
          public_housing: "no",
          nursing_home: "no",
          household_fed_agi: 1234,
          household_ny_additions: 1234,
          household_ssi: 1234,
          household_cash_assistance: 1234,
          household_other_income: 1234,
          household_rent_own: "own",
          household_rent_amount: 0,
          household_rent_adjustments: 123,
          household_own_propety_tax: 123,
          household_own_assessments: 123,
        }
      end
    end
  end
end
