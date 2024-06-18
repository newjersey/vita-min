module StateFile
  module Questions
    class ReturnStatusController < AuthenticatedQuestionsController
      include StateFile::SurveyLinksConcern
      before_action :redirect_if_from_efile
      before_action :redirect_if_no_submission
      skip_before_action :redirect_if_in_progress_intakes_ended

      def edit
        @submission_to_show = submission_to_show
        @error = submission_error
        @return_status = return_status
        @refund_url = refund_url
        @tax_payment_url = tax_payment_url
        @download_form_name = download_form_name
        @mail_voucher_address = mail_voucher_address
        @voucher_path = voucher_path
        @survey_link = survey_link(current_intake)
      end

      def prev_path
        nil
      end

      private

      def submission_to_show
        is_az_intake = current_intake.is_a?(StateFileAzIntake)
        latest_submission_has_901_error = current_intake.latest_submission&.efile_submission_transitions&.where(to_state: "rejected")&.last&.efile_errors&.pluck(:code)&.include?("901")
        accepted_submissions = current_intake.efile_submissions.filter { |submission| submission.in_state?(:accepted) }

        if is_az_intake && latest_submission_has_901_error && accepted_submissions.present?
          accepted_submissions.last
        else
          current_intake.latest_submission
        end
      end

      def submission_error
        return nil unless return_status == 'rejected'
        # in the case that its in the notified_of_rejection or waiting state
        # we can't just grab the efile errors from the last transition
        submission_to_show&.efile_submission_transitions&.where(to_state: 'rejected')&.last&.efile_errors&.last
      end

      def return_status
        # return status for display
        case submission_to_show.current_state
        when 'accepted'
          'accepted'
        when 'notified_of_rejection', 'waiting'
          'rejected'
        else
          'pending'
        end
      end

      def refund_url
        case current_state_code
        when 'ny'
          'https://www.tax.ny.gov/pit/file/refund.htm'
        when 'az'
          'https://aztaxes.gov/home/checkrefund'
        else
          ''
        end
      end

      def tax_payment_url
        case current_state_code
        when 'ny'
          'Tax.NY.gov'
        when 'az'
          'AZTaxes.gov'
        else
          ''
        end
      end

      def download_form_name
        case current_state_code
        when 'ny'
          'Form IT-201-V'
        when 'az'
          'Form AZ-140V'
        else
          ''
        end
      end

      def mail_voucher_address
        case current_state_code
        when 'ny'
          "NYS Personal Income Tax<br/>"\
          "Processing Center<br/>"\
          "Box 4124<br/>"\
          "Binghamton, NY 13902-4124".html_safe
        when 'az'
          "Arizona Department of Revenue<br/>"\
          "PO Box 29085<br/>"\
          "Phoenix, AZ 85038-9085".html_safe
        else
          ''
        end
      end

      def voucher_path
        case current_state_code
        when 'ny'
          '/pdfs/it201v_1223.pdf'
        when 'az'
          '/pdfs/AZ-140V.pdf'
        else
          ''
        end
      end

      def card_postscript; end

      def redirect_if_no_submission
        if current_intake.efile_submissions.empty?
          redirect_to StateFile::Questions::InitiateDataTransferController.to_path_helper(us_state: current_state_code)
        end
      end

      def redirect_if_from_efile
        # We had a situation where we gave the wrong URL to direct file, and they were redirecting
        # here when the federal return was not yet approved.
        # We have alerted them, and once they have updated their URL we can probably remove this
        if params[:ref_location] == "df_authorize_state"
          redirect_to StateFile::Questions::PendingFederalReturnController.to_path_helper(us_state: current_state_code)
        end
      end
    end
  end
end
