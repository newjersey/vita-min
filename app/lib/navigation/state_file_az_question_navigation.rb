module Navigation
  class StateFileAzQuestionNavigation
    include ControllerNavigation

    FLOW = [
      StateFile::Questions::LandingPageController,
      StateFile::Questions::ContactPreferenceController, # creates state_intake (StartIntakeConcern)
      StateFile::Questions::PhoneNumberController,
      StateFile::Questions::EmailAddressController,
      StateFile::Questions::VerificationCodeController,
      StateFile::Questions::CodeVerifiedController,
      StateFile::Questions::InitiateDataTransferController,
      StateFile::Questions::WaitingToLoadDataController,
      StateFile::Questions::FederalInfoController,
      StateFile::Questions::FederalDependentsController,
      StateFile::Questions::DobController,
      StateFile::Questions::AzSeniorDependentsController,
      StateFile::Questions::AzPriorLastNamesController,
      StateFile::Questions::UnemploymentController,
      StateFile::Questions::AzStateCreditsController,
      StateFile::Questions::AzCharitableContributionsController,
      StateFile::Questions::SubmitReturnController,
      StateFile::Questions::ConfirmationController
    ].freeze

    def self.intake_class
      StateFileAzIntake
    end
  end
end
