require 'json'

module StateFile
  module Questions
    class NjCountyController < QuestionsController
      include ReturnToReviewConcern

      def edit
        @filing_year = Rails.configuration.statefile_current_tax_year
        municipalities_path = Rails.root.join("app/lib/efile/nj/municipalities.json")
        municipalities_json = File.read(municipalities_path)
        parsed_municipalities = JSON.parse(municipalities_json)
        @counties = parsed_municipalities.map {|municipality| municipality['county']}.uniq.sort
        super
      end
    end
  end
end
