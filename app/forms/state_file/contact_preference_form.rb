module StateFile
  class ContactPreferenceForm < QuestionsForm
    set_attributes_for :intake, :contact_preference
    def save
      @intake.update(attributes_for(:intake))
    end
  end
end