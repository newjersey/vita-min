module Ctc
  module Questions
    class IncomeController < QuestionsController
      include AnonymousIntakeConcern

      layout "yes_no_question"

      def method_name
        "income_qualifies"
      end

      private

      def illustration_path
        "hand-holding-check.svg"
      end

      def next_path
        @form.income_qualifies? ? super : questions_use_gyr_path
      end

      def tracking_data
        @form.attributes_for(:misc)
      end
    end
  end
end
