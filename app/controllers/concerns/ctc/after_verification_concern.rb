module Ctc
  module AfterVerificationConcern
    extend ActiveSupport::Concern

    private

    def after_verification_actions
      send_mixpanel_event(event_name: "ctc_contact_verified")
      sign_in current_intake.client
      current_intake.tax_returns.last.update(status: "intake_in_progress")

      ClientMessagingService.send_system_message_to_all_opted_in_contact_methods(
        client: current_intake.client,
        message: AutomatedMessage::CtcGettingStarted.new,
        locale: current_intake.locale
      )
    end
  end
end
