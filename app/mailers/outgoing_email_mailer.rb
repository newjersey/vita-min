class OutgoingEmailMailer < ApplicationMailer
  def user_message(outgoing_email:)
    @outgoing_email = outgoing_email
    attachment = outgoing_email.attachment

    service_type = @outgoing_email.client.intake.is_ctc? ? :ctc : :gyr
    service = MultiTenantService.new(service_type)
    @service_type = service.service_type

    @body = outgoing_email.body
    @subject = outgoing_email.subject
    if attachment.present?
      attachments[attachment.filename.to_s] = attachment.blob.download
    end

    DatadogApi.increment("mailgun.outgoing_emails.sent")

    mail(
      to: outgoing_email.to,
      subject: @subject,
      from: service.from_email,
      delivery_method_options: service.delivery_method_options
    )
  end
end
