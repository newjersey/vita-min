module StateFile
  class ReminderToFinishStateReturnService
    def self.run
      cutoff_time_ago = 12.hours.ago
      batch_size = 10
      intakes_with_no_submission = StateFileAzIntake.where("df_data_imported_at < ?", cutoff_time_ago)
                                                    .left_joins(:efile_submissions)
                                                    .where(efile_submissions: { id: nil })
                                                    .where.not("state_file_az_intakes.message_tracker #> '{messages.state_file.finish_return}' IS NOT NULL")

      intakes_with_no_submission += StateFileNyIntake.where("df_data_imported_at < ?", cutoff_time_ago)
                                                     .left_joins(:efile_submissions)
                                                     .where(efile_submissions: { id: nil })
                                                     .where.not("state_file_ny_intakes.message_tracker #> '{messages.state_file.finish_return}' IS NOT NULL")

      intakes_with_no_submission.each_slice(batch_size) do |batch|
        batch.each do |intake|
          StateFile::MessagingService.new(message: StateFile::AutomatedMessage::FinishReturn, intake: intake).send_message
        end
      end
    end
  end
end
