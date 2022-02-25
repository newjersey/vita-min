class VerificationAttemptStateMachine
  include Statesman::Machine

  state :pending, initial: true
  state :approved
  state :denied
  state :escalated
  state :requested_replacements

  transition from: :pending, to: [:approved, :denied, :escalated, :requested_replacements]
  transition from: :escalated, to: [:approved, :denied, :requested_replacements]

  after_transition(to: :approved, after_commit: true) do |verification_attempt, transition|
    verification_attempt.client.update(identity_verified_at: transition.created_at)
    efile_submission = verification_attempt.client.efile_submissions&.last
    if efile_submission.present? && efile_submission.in_state?(:fraud_hold)
      efile_submission.transition_to(:resubmitted, { initiated_by_id: transition.metadata[:initiated_by_id] })
    end
  end

  after_transition(to: :denied, after_commit: true) do |verification_attempt, transition|
    verification_attempt.client.update(identity_verification_denied_at: transition.created_at)
    ClientMessagingService.send_system_message_to_all_opted_in_contact_methods(
      client: verification_attempt.client,
      message: AutomatedMessage::VerificationAttemptDenied,
      locale: verification_attempt.client.intake.locale,
    )
  end

  after_transition(to: :requested_replacements, after_commit: true) do |verification_attempt, transition|
    ClientMessagingService.send_system_message_to_all_opted_in_contact_methods(
      client: verification_attempt.client,
      message: AutomatedMessage::NewPhotosRequested,
      locale: verification_attempt.client.intake.locale,
    )
  end
end