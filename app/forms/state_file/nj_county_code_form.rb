module StateFile
  class NjCountyCodeForm < QuestionsForm
    set_attributes_for :intake,
                       :residence_county_code

    validates :residence_county_code, presence: true

    def save
      @intake.assign_attributes(attributes_for(:intake))
      @intake.save
    end
  end
end