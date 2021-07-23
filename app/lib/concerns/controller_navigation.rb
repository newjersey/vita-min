module ControllerNavigation
  extend ActiveSupport::Concern
  attr_reader :current_controller
  included do
    class << self
      delegate :first, to: :controllers

      def controllers
        const_get("FLOW")
      end
    end

    delegate :controllers, to: :class
  end

  def initialize(current_controller)
    @current_controller = current_controller
  end

  def next
    return unless index

    controllers_until_end = controllers[index + 1..-1]
    seek(controllers_until_end)
  end

  def prev(&additional_check)
    return unless index&.nonzero?

    controllers_to_beginning = controllers[0..index - 1].reverse
    seek(controllers_to_beginning, &additional_check)
  end

  private

  def index
    controllers.index(current_controller.class)
  end

  def seek(list, &additional_check)
    list.detect do |controller_class|
      next if additional_check && !additional_check.call(controller_class)
      model = controller_class.model_for_show_check(current_controller)
      controller_class.show?(model)
    end
  end
end
