require 'json'

module StateFile
  module Questions
    class NjCountyCodeController < QuestionsController
      include ReturnToReviewConcern

      def edit
        @filing_year = Rails.configuration.statefile_current_tax_year
        municipalities_path = Rails.root.join("app/lib/efile/nj/municipalities.json")
        municipalities_json = File.read(municipalities_path)
        parsed_municipalities = JSON.parse(municipalities_json)
        municipalities_for_county = parsed_municipalities.select {|municipality| municipality['county'] == current_intake.residence_county }
        # TODO: municipalities json is copied from an old file
        # Update it, then see whether it's still necessary to add leading 0 to match IndividualStateEnumerations.xsd spec
        @municipalities = municipalities_for_county.map { |municipality| [municipality['municipality'], "0" + municipality['code']] }
        super
      end
    end
  end
end
