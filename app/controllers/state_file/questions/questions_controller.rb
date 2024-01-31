module StateFile
  module Questions
    class QuestionsController < ::Questions::QuestionsController
      include StateFile::StateFileControllerConcern
      before_action :redirect_if_no_intake
      helper_method :card_postscript

      # default layout for all state file questions
      layout "state_file/question"

      def ip_for_irs
        if Rails.env.test?
          "72.34.67.178"
        else
          request.remote_ip
        end
      end

      private

      def current_intake
        intake = GlobalID.find(session[:state_file_intake])
        return nil if intake && !intake.is_a?(question_navigator.intake_class)
        intake
      end

      def question_navigator
        case params[:us_state]
        when 'az'
          Navigation::StateFileAzQuestionNavigation
        when 'ny'
          Navigation::StateFileNyQuestionNavigation
        end
      end

      def redirect_if_no_intake
        unless current_intake.present?
          flash[:notice] = 'Your session expired. Please sign in again to continue.'
          if params['us_state'] == 'az'
            redirect_to az_questions_landing_page_path(us_state: params['us_state'])
          else
            redirect_to ny_questions_landing_page_path(us_state: params['us_state'])
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

      def prev_path
        path_for_step(form_navigation.prev)
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
