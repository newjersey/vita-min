require 'rails_helper'

RSpec.feature 'Flow visualizations' do
  describe 'GYR' do
    it 'shows all the pages' do
      visit flow_path(id: :gyr)

      expected_controllers = Navigation::GyrQuestionNavigation::FLOW.reject { |c| c.deprecated_controller? }

      expected_controllers.each do |controller|
        expect(page).to have_content(controller.name)
      end
    end
  end
end
