module StateFile
  module Questions
    class QuestionsController < ::Questions::QuestionsController
      before_action :redirect_if_no_intake
      before_action :redirect_if_in_progress_intakes_ended
      helper_method :card_postscript, :current_tax_year, :state_name, :state_code

      # default layout for all state file questions
      layout "state_file/question"

      def ip_for_irs
        if Rails.env.test?
          "72.34.67.178"
        else
          request.remote_ip
        end
      end

      def state_code
        state_from_params = params[:us_state]
        unless StateFile::StateInformationService.active_state_codes.include?(state_from_params)
          raise StandardError, state_from_params
        end
        state_from_params
      end

      def state_name
        StateFile::StateInformationService.state_name(state_code)
      end

      def current_tax_year
        MultiTenantService.new(:statefile).current_tax_year
      end

      private

      def current_intake
        state_code = question_navigator.intake_class.state_code
        send("current_state_file_#{state_code}_intake")
      end

      def question_navigator
        @navigator ||= "Navigation::StateFile#{state_code.titleize}QuestionNavigation".constantize
      end
      helper_method :question_navigator

      def redirect_if_no_intake
        unless current_intake.present?
          flash[:notice] = 'Your session expired. Please sign in again to continue.'
          redirect_to StateFile::StateFilePagesController.to_path_helper(action: :login_options, us_state: state_code)
        end
      end

      def redirect_if_in_progress_intakes_ended
        if app_time.after?(Rails.configuration.state_file_end_of_in_progress_intakes)
          if current_intake.efile_submissions.empty?
            redirect_to root_path
          else
            redirect_to StateFile::Questions::ReturnStatusController.to_path_helper(action: :edit, us_state: state_code)
          end
        end
      end

      def next_step
        form_navigation.next
      end

      def next_path
        step_for_next_path = next_step
        options = { us_state: params[:us_state], action: step_for_next_path.navigation_actions.first }
        if step_for_next_path.resource_name.present? && step_for_next_path.resource_name == self.class.resource_name
          options[:id] = current_resource.id
        end
        step_for_next_path.to_path_helper(options)
      end

      def prev_step
        form_navigation.prev
      end

      def prev_path
        path_for_step(prev_step)
      end

      def path_for_step(step)
        return unless step
        options = { us_state: params[:us_state], action: step.navigation_actions.first }
        if step.resource_name
          options[:id] = step.model_for_show_check(self)&.id
        end
        step.to_path_helper(options)
      end

      # by default, most state file questions have no illustration
      def illustration_path; end

      def card_postscript; end

      def update_for_device_id_collection(efile_device_info)
        @form = initialized_update_form
        if form_params["device_id"].blank? && efile_device_info&.device_id.blank?
          flash[:alert] = I18n.t("general.enable_javascript")
          redirect_to render: :edit
        else
          flash.clear
          method(:update).super_method.call
        end
      end

      class << self
        def resource_name
          nil
        end

        def form_key
          "state_file/" + controller_name + "_form"
        end
      end
    end
  end
end
