module StateFile
  module Questions
    class NjEligibilityResidenceController < QuestionsController
      include EligibilityOffboardingConcern
    end
  end
end