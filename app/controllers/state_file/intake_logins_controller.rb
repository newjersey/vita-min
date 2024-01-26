module StateFile
  class IntakeLoginsController < Portal::ClientLoginsController
    helper_method :prev_path, :illustration_path
    before_action :redirect_to_data_review_if_intake_authenticated
    layout "state_file/question"

    def new
      @contact_method = params[:contact_method]
      unless ["email_address", "sms_phone_number"].include?(@contact_method)
        return render "public_pages/page_not_found", status: 404
      end
      super
    end

    def create
      @contact_method = params[:contact_method] unless @contact_method.present?
      super
    end

    def edit
      @form = IntakeLoginForm.new(possible_intakes: @records)
    end

    def update
      @form = IntakeLoginForm.new(intake_login_params)
      if @form.valid?
        sign_in @form.intake
        session[:state_file_intake] = @form.intake.to_global_id
        redirect_to session.delete(:after_state_file_intake_login_path) || StateFile::Questions::DataReviewController.to_path_helper(us_state: params[:us_state])
      else
        @records.each(&:increment_failed_attempts)

        # Re-checking if account is locked after incrementing
        return if redirect_locked_clients

        render :edit
      end
    end

    private
    def prev_path; end

    def illustration_path; end

    def extra_path_params
      {
        us_state: params[:us_state]
      }
    end

    def intake_login_params
      params.require(:state_file_intake_login_form).permit(:ssn).merge(possible_intakes: @records)
    end

    def increment_failed_attempts_on_login_records
      model = MultiTenantService.new(service_type).intake_model
      contact_info = params[:portal_verification_code_form][:contact_info]
      @records = model.where(email_address: contact_info).or(model.where(phone_number: contact_info))
      @records.map(&:increment_failed_attempts)
    end

    def request_login_form_class
      RequestIntakeLoginForm
    end

    def request_client_login_params
      params.require(:state_file_request_intake_login_form).permit(:email_address, :sms_phone_number)
    end

    def service_type
      case params[:us_state]
      when "az" then :statefile_az
      when "ny" then :statefile_ny
      end
    end

    def redirect_to_data_review_if_intake_authenticated
      redirect_to StateFile::Questions::DataReviewController.to_path_helper(us_state: params[:us_state]) if current_state_file_az_intake.present? || current_state_file_ny_intake.present?
    end
  end
end