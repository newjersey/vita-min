shared_examples :a_normal_page_when_intake_is_open do |controller, action: :edit|
  describe "when intake is open" do
    before do
      allow(Rails.configuration).to receive(:start_of_unique_links_only_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:start_of_open_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:end_of_intake).and_return(1.minute.from_now)
    end

    it "renders normally" do
      get controller.to_path_helper(action: action)
      expect(response).to be_ok
    end
  end
end

shared_examples :a_normal_page_when_intake_is_closed do |controller, action: :edit|
  describe "when intake is closed" do
    before do
      allow(Rails.configuration).to receive(:start_of_unique_links_only_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:start_of_open_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:end_of_intake).and_return(1.minute.ago)
    end

    it "renders normally" do
      get controller.to_path_helper(action: action)
      expect(response).to be_ok
    end
  end
end


shared_examples :a_redirect_home_when_intake_is_closed do |controller, action: :edit|
  describe "when intake is closed" do
    before do
      allow(Rails.configuration).to receive(:start_of_unique_links_only_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:start_of_open_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:end_of_intake).and_return(1.minute.ago)
    end

    it "redirects to home" do
      get controller.to_path_helper(action: action)
      expect(response).to redirect_to root_path
    end
  end
end


shared_examples :a_redirect_home_when_login_is_closed do |controller, action: :edit|
  describe "when login is closed" do
    before do
      allow(Rails.configuration).to receive(:start_of_unique_links_only_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:start_of_open_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:end_of_intake).and_return(1.minute.ago)
      allow(Rails.configuration).to receive(:end_of_login).and_return(1.second.ago)
    end

    it "redirects to home" do
      get controller.to_path_helper(action: action)
      expect(response).to redirect_to root_path
    end
  end
end
