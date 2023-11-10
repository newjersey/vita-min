module StateFile
  class AzCharitableContributionsForm < QuestionsForm
    set_attributes_for :intake, :charitable_contributions, :charitable_cash, :charitable_noncash

    validates :charitable_contributions, inclusion: { in: %w[yes no], message: I18n.t("errors.messages.blank") }
    validates :charitable_cash, presence: true, gyr_numericality: { only_integer: true }, allow_blank: false, if: -> { charitable_contributions == "yes" }
    validates :charitable_noncash, presence: true, gyr_numericality: { only_integer: true, less_than_or_equal_to: 500 }, allow_blank: false, if: -> { charitable_contributions == "yes" }


    def save
      if charitable_contributions == "no"
        @intake.update(charitable_contributions: "no", charitable_cash: nil, charitable_noncash: nil)
      else
        @intake.update(attributes_for(:intake))
      end
    end
  end
end