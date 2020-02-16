# frozen_string_literal: true

module Questions
  class Form1099ssController < DocumentUploadQuestionController
    def self.show?(intake)
      intake.had_asset_sale_income_yes? || intake.sold_a_home_yes?
    end

    private

    def document_type
      "1099-S"
    end
  end
end
