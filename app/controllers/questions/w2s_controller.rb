module Questions
  class W2sController < DocumentUploadQuestionController
    def self.show?(intake)
      intake.had_wages_yes? ||
        intake.had_disability_income_yes? ||
        intake.had_a_job?
    end

    private

    def document_type
      "W-2"
    end
  end
end
